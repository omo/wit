#!/usr/bin/env ruby

# Trap interrupts to quit cleanly. See
# https://github.com/bundler/bundler/blob/master/bin/bundle
Signal.trap("INT") { exit 1 }

require 'wit/cli'


Wit::CLI.start(ARGV)
