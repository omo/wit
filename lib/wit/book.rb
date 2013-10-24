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
      Dir.glob(File.join(@filename, "*." + type)).map { |n| NoteName.new(n) }
    end

    def <=>(other)
      self.url <=> other.url
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
      NoteName.new(File.join(@noteroot, "#{yyyy}_#{mm}", "#{yyyy}_#{mm}_#{dd}_#{hhmm}_#{title}.#{type}"))
    end

    def page_name_from_label(label, type = :md)
      raise NotFound unless TYPES.include?(type)
      raise NotFound unless label =~ /[[:alnum:]]+/
      PageName.new(File.join(@pageroot, "#{label}.#{type}"))
    end

    def page_names
      Enumerator.new do |y|
        Dir.glob(File.join(@pageroot, "*.md")).sort.map do |path| 
          y << PageName.new(path) 
        end
      end
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

    def to_note(name, options = {})
      raise NotFound unless (name.exist? or options[:fresh])
      note = name.to_note
      raise Forbidden unless note.published? or thinking?
      return note
    end

    def to_notes(names)
      # FIXME: Could be written as Enumerator
      names.inject([]) do |a, name|
        if name.exist?
          note = name.to_note
          a << note if note.published? or thinking?
        end
        a
      end
    end

    def covername() NoteName.new(File.join(@noteroot, "cover.md")); end
    def cover() to_note(covername); end

    def latest_note_names
      raise unless thinking?
      Enumerator.new do |y|
        Dir.glob(File.join(@noteroot, "*")).sort.reverse.each do |dir|
          Dir.glob(File.join(dir, "*.md")).sort.reverse.each do |note|
            y << NoteName.new(note)
          end
        end
      end
    end
    
    def months
      Dir.glob(File.join(@noteroot, "*")).inject([]) do |a, dir|
        if File.directory?(dir)
          y, m = File.basename(dir).split("_").map { |i| i.to_i }
          a << Month.new(y, m, dir)
        end
        a
      end.sort
    end

    def month_from_components(yyyy, mm)
      raise NotFound unless yyyy  =~ /\d\d\d\d/
      raise NotFound unless   mm  =~ /\d\d/
      Month.new(yyyy.to_i, mm.to_i, File.join(@noteroot, "#{yyyy}_#{mm}"))
    end

    def month_of(name)
      month_from_components(name.components.digits[0], name.components.digits[1])
    end

    def make_pathlike(title)
      return "index" if nil == title || title.empty?
      title.gsub(/[^(A-Za-z0-9)]+/, "-").gsub(/^\-|\-$/, "").downcase
    end

    def fresh_note_name(title)
      # FIXME: Should avoid conflict
      now = Time.now
      name_from_components(now.strftime("%Y"), now.strftime("%m"), now.strftime("%d"), now.strftime("%H%M"), make_pathlike(title), :md)
    end

    def initialize(root, options={})
      @noteroot = File.join(root, "n")
      @pageroot = File.join(root, "p")
      @options = options
    end

    def thinking?() @options[:thinking]; end
  end
end
