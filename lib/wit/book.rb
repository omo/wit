# encoding: utf-8

require 'wit/base'
require 'wit/name'
require 'wit/note'
require 'erb'

module Wit
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

    def to_note(name)
      raise NotFound unless name.exist?
      note = name.to_note
      raise Forbidden unless note.published? or thinking?
      return note
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
