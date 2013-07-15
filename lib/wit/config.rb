# encoding: utf-8

module Wit

  # FIXME: Should be in its own file
  class Config
    attr_reader :options

    def initialize
      @options = {}
    end

    def load(path)
      File.open(path) do |f|
        instance_eval(f.read)
      end
    end

    def self.make(path)
      created = self.new
      if true
        created.load(path) 
      else
        # TODO: Write default
      end

      created
    end

    # FIXME: Could be concise
    def repopath() options[:repopath]; end
    def repourl() options[:repourl]; end
    def cookie_secret() options[:cookie_secret]; end
    def github_client_id() options[:github_client_id]; end
    def github_client_secret() options[:github_client_secret]; end
    def github_login() options[:github_login]; end
  end
end
