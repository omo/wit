# encoding: utf-8

require 'wit/repo'

module Wit
  module RepoOwnable
    def repo
      @repo ||= @@repo ||= Wit::Repo.new(settings.repopath, settings.repourl)
    end
  end

  module SettingComposable
    def self.included(base)
      def base.set(key, val) self.each_app { |app| app.set(key, val) }; end
      def base.enable(key) self.each_app { |app| app.enable(key) }; end
      def set(key, val) self.class.set(key, val); end
      def enable(key) self.class.enable(key); end
    end
  end

  module ApiServable
    def req_hash
      @req_hash ||= JSON.parse(request.body.read)
    end

    def api_request?
      request.content_type == "application/json"
    end

    def should_be_api_request
      halt 400 unless api_request?
    end

    def required_value_of(key_name)
      halt 400, "Should have key: #{key_name}" unless req_hash.has_key?(key_name)
      req_hash[key_name]
    end
  end
end
