# encoding: utf-8

require 'wit/base'
require 'wit/name'
require 'wit/note'
require 'liquid' # for Month

module Wit

  class Month
    MONTH_NAMES = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
    liquid_methods :to_s, :yyyy, :mm, :url, :month_abbrev, :names
    attr_reader :filename

    def initialize(y, m, filename=nil)
      @y = y
      @m = m
      @filename = filename
    end

    def yyyy() sprintf("%04d", @y); end
    def   mm() sprintf("%02d", @m); end
    def to_s() "#{yyyy}/#{mm}"; end
    def url() "/#{yyyy}/#{mm}"; end
    def month_abbrev() MONTH_NAMES[@m - 1]; end

    def names
      type = "md"
      Dir.glob(File.join(@filename, "*." + type)).map { |n| Name.new(n) }
    end
  end

  class Book
    def name_from_components(yyyy, mm, dd, hhmm, title, type)
      raise NotFound unless yyyy  =~ /\d\d\d\d/
      raise NotFound unless   mm  =~ /\d\d/
      raise NotFound unless   dd  =~ /\d\d/
      raise NotFound unless hhmm  =~ /\d\d\d\d/
      raise NotFound unless title =~ /(\w|\d|\-)+/ or title == nil
      raise NotFound unless TYPES.include?(type)
      title = "index" unless title
      Name.new(File.join(@root, "#{yyyy}_#{mm}", "#{yyyy}_#{mm}_#{dd}_#{hhmm}_#{title}.#{type}"))
    end

    def md_name_from_components(yyyy, mm, dd, hhmmtitle)
      m = /(\d+)\-(.*)/.match(hhmmtitle)
      if m
        hhmm  = m[1]
        title = m[2]
        name_from_components(yyyy, mm, dd, hhmm, title, :md)
      else
        name_from_components(yyyy, mm, dd, hhmmtitle, nil, :md)
      end
    end

    def to_note(name)
      raise NotFound unless name.exist?
      note = name.to_note
      raise Forbidden unless note.published? or thinking?
      return note
    end

    def to_notes(names)
      names.inject([]) do |a, name|
        if name.exist?
          note = name.to_note
          a << note if note.published? or thinking?
        end
        a
      end
    end

    def covername() Name.new(File.join(@root, "cover.md")); end
    def cover() to_note(covername); end

    def latest_note_names
      raise unless thinking?
      Enumerator.new do |y|
        Dir.glob(File.join(@root, "*")).reverse.each do |dir|
          Dir.glob(File.join(dir, "*.md")).reverse.each do |note|
            y << Name.new(note)
          end
        end
      end
    end

    def months
      Dir.glob(File.join(@root, "*")).inject([]) do |a, dir|
        if File.directory?(dir)
          y, m = File.basename(dir).split("_").map { |i| i.to_i }
          a << Month.new(y, m, dir)
        end
        a
      end
    end

    def month_from_components(yyyy, mm)
      raise NotFound unless yyyy  =~ /\d\d\d\d/
      raise NotFound unless   mm  =~ /\d\d/
      Month.new(yyyy.to_i, mm.to_i, File.join(@root, "#{yyyy}_#{mm}"))
    end

    def make_pathlike(title)
      title.gsub(/[^(A-Za-z0-9)]+/, "-").gsub(/^\-|\-$/, "").downcase
    end

    def fresh_note_name(title)
      # FIXME: Should avoid conflict
      now = Time.now
      name_from_components(now.strftime("%Y"), now.strftime("%m"), now.strftime("%d"), now.strftime("%H%M"), title ? make_pathlike(title) : nil, :md)
    end

    def initialize(root, options={})
      @root = root
      @options = options
    end

    def thinking?() @options[:thinking]; end
  end
end
