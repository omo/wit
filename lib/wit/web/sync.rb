# encoding: utf-8

require 'sinatra/base'
require 'wit/repo'
require 'wit/web/helpers'

module Wit
  class SyncWeb < Sinatra::Base
    include RepoOwnable

    get '/' do
      liquid :sync, layout: :layout
    end

    post '/' do
      repo.sync
      "done"
    end
  end
end
