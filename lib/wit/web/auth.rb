# encoding: utf-8

require 'cgi'
require 'open-uri'
require 'json'
require 'rack/cascade'
require 'rack/utils'
require 'sinatra/base'
require 'uri/http'
require 'net/http'
require 'wit/repo'
require 'wit/web/helpers'

module Wit

  class AuthHelper
    def initialize(settings)
      @settings = settings
    end

    def redirect_uri(redirected_from)
      # FIXME: should set "state" parameter
      callback = "http://wit.flakiness.es/~/authback?from=" + CGI.escape(redirected_from)
      q = { client_id: @settings.github_client_id, redirect_uri: callback }
      URI::HTTPS.build(host: "github.com", path: "/login/oauth/authorize", query: to_query(q)).to_s
    end

    def ask_who(code)
      token_q = { "client_id" => @settings.github_client_id, "client_secret" => @settings.github_client_secret, "code" => code }
      token_url = URI::HTTPS.build(host: "github.com", path: "/login/oauth/access_token")
      token_result = Rack::Utils.parse_nested_query(post_url(token_url, token_q).read)
      token = token_result["access_token"]
      user_q = { access_token: token }
      user_url = URI::HTTPS.build(host: "api.github.com", path: "/user", query: to_query(user_q))
      user_result = JSON.load(get_url(user_url.to_s))
      login = user_result["login"]
      [login, token]
    end

    def get_url(url)
      open(url)
    end

    def post_url(url, params)
      resp = Net::HTTP.post_form(url, params)
      raise unless resp.code == "200"
      StringIO.new(resp.body)
    end

    private

    def to_query(hash)
      hash.map { |k, v| k.to_s + "=" + CGI.escape(v) }.join("&") 
    end
  end
  
  class TestingAuthHelper < AuthHelper
    def get_url(url)
      case url
      when "https://api.github.com/user?access_token=testtoken"
        return '{"login": "octocat"}'
      else
        raise "Bug!: #{url}"
      end
    end

    def post_url(url, params)
      case url
      when URI.parse("https://github.com/login/oauth/access_token")
        StringIO.new("access_token=testtoken")
      else
        raise "Bug!: #{url}"
      end
    end
  end

  class AuthWeb < Sinatra::Base
    Forbidden = [403, {"Content-Type" => "text/plain"}, []]

    get '/authback' do
      login = settings.github_login
      raise "settings.github_login should be givne!" unless login

      code = request["code"]
      from = request["from"]
      halt 403, "No sufficient parameters" unless (code and from)
      # FIXME: See if |from| is in the same domain.
      # FIXME: Ask github here.
      helper = auth_helper_class.new(settings)
      who, token = helper.ask_who(code)
      halt 403, "Sorry #{who}, but you're not me." if who != login
      session[:github_login] = who
      session[:github_token] = token
      redirect to(from)
    end

    get '/*' do
      # FIXME: fix the test side to make this less error-prone.
      return Rack::Cascade::NotFound if settings.disable_auth

      case authorize(request, session)
      when :needs_authentication
        redirect to(auth_helper_class.new(settings).redirect_uri(request.url))
      when :forbidden
        session.clear
        Forbidden  
      when :eligible
        Rack::Cascade::NotFound
      else
        raise "Bug!"
      end        
    end

    def authorize(request, session)
      raise "Github Login should be set!" unless settings.github_login
      case session[:github_login]
      when settings.github_login
        :eligible
      when nil
        :needs_authentication
      else
        :forbidden
      end
    end

    def auth_helper_class
      if settings.environment == :test
        TestingAuthHelper
      else
        AuthHelper
      end
    end
    
  end

  def self.make_authed_class(base)
    Class.new(Rack::Cascade) do
      include SettingComposable
      self.class_variable_set(:@@base_class, base)

      def self.each_app(&block)
        [AuthWeb, self.class_variable_get(:@@base_class)].each(&block);
      end

      def initialize()
        super([AuthWeb, self.class.class_variable_get(:@@base_class)])
      end
    end
  end
end
