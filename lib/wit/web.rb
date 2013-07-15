# encoding: utf-8

require 'encrypted_cookie'
require 'rack/urlmap'
require 'wit/web/helpers'
require 'wit/web/sync'
require 'wit/web/book'
require 'wit/web/auth'

module Wit
  class Web < Rack::URLMap
    include SettingComposable

    APPS = {
      "/" => PublishedBookWeb,
      "/~" => Wit::make_authed_class(ThinkingBookWeb).new,
      "/sync" => Wit::make_authed_class(SyncWeb).new
    }

    def self.each_app(&block) APPS.values.each(&block); end
    def initialize() super(APPS); end

    # App-specific continuation.
    set(:disable_auth, false)
  end
end
