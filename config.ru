#!/usr/bin/env rackup
# encoding: utf-8

$LOAD_PATH << "./lib"

require 'wit/web'
require 'wit/config'

CONFIG = Wit::Config.make("./config/witweb.conf")

class RackupWeb < Wit::Web
  set(:repopath, File.expand_path(CONFIG.repopath))
  set(:repourl, File.expand_path(CONFIG.repourl))
  [:cookie_secret, :github_client_id, :github_client_secret, :github_login].each do |key|
    set(key, CONFIG.send(key))
  end

  # For debug.
  set(:disable_auth, true) if ENV["RACK_ENV"] == "development"
end

use(Rack::Session::EncryptedCookie,
    key: 'rack.session',
    expire_after: 2592000,
    secret: CONFIG.cookie_secret)
run RackupWeb.new
