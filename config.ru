#!/usr/bin/env rackup
# encoding: utf-8

$LOAD_PATH << "./lib"

require 'wit/web'
require 'wit/config'

class RackupWeb < Wit::Web
  config = Wit::Config.make("./config/witweb.conf")
  set(:repopath, File.expand_path(config.repopath))
end 

run RackupWeb
