#!/usr/bin/env rackup
# encoding: utf-8

$LOAD_PATH << "./lib"

require "./web"
run Sinatra::Application
