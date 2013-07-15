# encoding: utf-8

require 'wit/repo'

module Wit
  module RepoOwnable
    def repo
      @@repo ||= Wit::Repo.new(settings.repopath, settings.repourl)
    end
  end
end
