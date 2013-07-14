# encoding: utf-8

require 'wit/notebook'

module Wit
  class Repo
    def initialize(path)
      @path = path
    end

    def thinking_book
      @thinking_book ||= Notebook.new(File.join(@path, "t"), thinking: true)
    end

    def published_book
      @publisehd_book ||= Notebook.new(File.join(@path, "t"))
    end
  end
end
