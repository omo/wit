#!/usr/bin/env rackup
# encoding: utf-8

$LOAD_PATH << "./lib"

require 'wit/web'
run Wit::Web
