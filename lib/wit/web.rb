# encoding: utf-8

require 'rack/urlmap'
require 'wit/web/sync'
require 'wit/web/book'

module Wit
  class Web < Rack::URLMap
    APPS = { "/" => BookWeb, "/sync" => SynWeb }

    def self.set(key, val) APPS.values.each { |app| app.set(key, val) }; end
    def self.enable(key) APPS.values.each { |app| app.enable(key) }; end
    def initialize() super(APPS); end
  end
end
