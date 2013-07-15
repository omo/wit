# encoding: utf-8

require 'rack/cascade'
require 'sinatra/base'
require 'wit/repo'
require 'wit/web/helpers'

module Wit
  class AuthWeb < Sinatra::Base
    Forbidden = [403, {"Content-Type" => "text/plain"}, []]

    get '/*' do
      # FIXME: fix the test side to make this less error-prone.
      return Rack::Cascade::NotFound if settings.environment == :test && request.path_info == "/latest" 
      Forbidden
    end
  end

  def self.make_authed_class(base)
    Class.new(Rack::Cascade) do
      @@base_class = base
      include SettingComposable

      def self.each_app(&block) [AuthWeb, @@base_class].each(&block); end
      def initialize() super([AuthWeb, @@base_class]); end
    end
  end
end
