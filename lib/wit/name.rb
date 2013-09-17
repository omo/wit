# encoding: utf-8

require 'fileutils'
require 'wit/base'

module Wit
  class Name
    attr_reader :filename

    def initialize(filename)
      @filename = filename
    end

    def ==(other) other.class == self.class and other.filename == self.filename; end
    def hash() self.filename.hash; end
    def exist?() File.exist?(@filename); end
  end
end
