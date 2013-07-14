# encoding: utf-8

require 'wit/notebook'
require 'fileutils'

module Wit
  class Repo
    def initialize(path, remote=nil)
      @path = path
      @remote = remote
    end

    def thinking_book
      @thinking_book ||= Notebook.new(File.join(@path, "t"), thinking: true)
    end

    def published_book
      @publisehd_book ||= Notebook.new(File.join(@path, "t"))
    end

    def fetch_or_clone
      if File.exist?(@path)
        raise unless File.directory?(@path)
        system("git fetch origin")
        raise unless 0 == $?
      else
        system("git clone #{@remote} #{@path}")
      end
    end

    def modified?
      !`git status --porcelain`.empty?
    end

    def commit
      message = "Synced at #{Time.now.to_s}"
      system("git add .")
      system("git commit -a -m \"#{message}\"")
    end

    def push
      system("git push origin master")
    end

    def merge
      system("git merge origin/master")
    end

    def sync
      FileUtils.makedirs(@path)
      Dir.chdir(@path) do 
        fetch_or_clone
        m = modified?
        commit if m
        merge
        push if m
      end
    end
  end
end
