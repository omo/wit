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
end
