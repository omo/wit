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
    def components() @components ||= split_to_components; end
    def url() components.to_u; end

    def walk(delta)
      # FIXME: impl
      raise if 1 < delta.abs
      # FIXME: handle non-md file
      siblings = Dir.glob(File.join(File.dirname(@filename), "*.md")).sort
      index = siblings.find_index(@filename)
      return Name.new(siblings[index + delta]) if (0 ... siblings.size).cover?(index + delta)

      dirdelta = delta # FIXME: Won't be true for |1 < delta.abs|
      dir = File.dirname(@filename)
      dirsibs = Dir.glob(File.join(File.dirname(dir), "*"))
      dirindex = dirsibs.find_index(dir)
      cursor = dirindex + dirdelta
      while true
        return nil unless (0 ... dirsibs.size).cover?(cursor)
        cousins = Dir.glob(File.join(dirsibs[cursor], "*.md")).sort
        return Name.new(0 < delta ? cousins.first : cousins.last) unless cousins.empty?
        cursor += dirdelta
      end
    end

    def exist?() File.exist?(@filename); end

    private
    
    def split_to_components
      # FIXME: take care of non-md type/suffix
      components = File.basename(@filename).gsub(/\..+$/, "").split("_")
      if components[-1] == "index"
        Components.new(components[0 .. -2], nil)
      else
        Components.new(components[0 .. -2], components[-1])
      end
    end

  end
end
