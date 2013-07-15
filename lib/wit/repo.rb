# encoding: utf-8

require 'wit/book'
require 'fileutils'

module Wit
  class Repo
    def initialize(path, remote=nil)
      @path = path
      @remote = remote
    end

    def thinking_book
      @thinking_book ||= Book.new(File.join(@path, "n"), thinking: true)
    end

    def published_book
      @publisehd_book ||= Book.new(File.join(@path, "n"))
    end

    def fetch_or_clone
      if File.exist?(@path)
        raise unless File.directory?(@path)
        git_in_repo("fetch origin")
        raise unless 0 == $?
      else
        system("git clone #{@remote} #{@path}")
      end
    end

    def modified?
      Dir.chdir(@path) do 
        !`git status --porcelain`.empty?
      end
    end

    def commit
      message = "Synced at #{Time.now.to_s}"
      git_in_repo("add .")
      git_in_repo("commit -a -m \"#{message}\"")
    end

    def push
      git_in_repo("push origin master")
    end

    def merge
      git_in_repo("merge origin/master")
    end

    def git_in_repo(subcommand)
      Dir.chdir(@path) do 
        system("git " + subcommand)
      end
    end

    def sync
      fetch_or_clone
      m = modified?
      commit if m
      merge
      push if m
    end
  end
end
