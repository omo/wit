# encoding: utf-8

require 'fileutils'
require 'wit/base'

module Wit
  class Name
    class Components < Struct.new(:digits, :title)
      def to_u
        # FIXME: take care of non-md type/suffix
        if self.title
          "/" + self.digits.join("/") + "-" + self.title
        else
          "/" + self.digits.join("/")
        end
      end
    end

    attr_reader :filename

    def initialize(filename)
      @filename = filename
    end

    def ==(other) other.class == self.class and other.filename == self.filename; end
    def hash() self.filename.hash; end
    def url() components.to_u; end
    def exist?() File.exist?(@filename); end
  end
end
