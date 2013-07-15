# encoding: utf-8

require 'fileutils'
require 'redcarpet'
require 'psych'
require 'liquid'
require 'erb'

module Wit
  TYPES = [:md]

  class Forbidden < StandardError; end
  class NotFound < StandardError; end

  # FIXME: Should have its own file
  class Name
    attr_reader :filename

    def initialize(filename)
      @filename = filename
    end

    def ==(other) other.class == self.class and other.filename == self.filename; end
    def hash() self.filename.hash; end

    def url
      # FIXME: take care of non-md type/suffix
      components = File.basename(@filename).gsub(/\..+$/, "").split("_")
      if components[-1] == "index"
        "/" + components[0 .. -2].join("/")
      else
        "/" + components[0 .. -2].join("/") + "-" + components[-1]
      end
    end

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
  end

  class NoteRenderer < Redcarpet::Render::HTML
    attr_reader :title

    def initialize
      super
      @title = nil
    end

    def header(title, level, &block)
      @title ||= title
      "<h#{level}>#{title}</h#{level}>" # Mimics redcarpet/html.c:rndr_header()
    end
  end

  # FIXME: should have its own file
  class Note
    liquid_methods :body, :url
    attr_reader :name

    def initialize(name)
      # FIXME: ensure if it is header-prepended markdown
      @name = name
      @body = nil
    end

    def exist?() name.exist?; end
    def url() name.url; end
    def published?() head["publish"]; end

    def head
      @head ||= Psych.load(head_text || '')
    end

    def body
      render
      @body
    end

    def title
      render
      @title
    end

BOILERPLATE = ERB.new(<<EOF
publish: false
----
<% if title %>
# <%= title %>
<% end %>
EOF
)

    def write_boilerplate(title=nil)
      raise "The file #{@name.filename} is already exist!" if exist?
      content = BOILERPLATE.result(binding)
      FileUtils.makedirs(File.dirname(@name.filename))
      open(@name.filename, "w:UTF-8") { |f| f.write content } unless File.exist?(@name.filename)
    end

    private

    def render
      return if @body
      opts = { :autolink => true, :space_after_headers => true }
      renderer = NoteRenderer.new
      md = Redcarpet::Markdown.new(renderer, opts)
      @body = md.render(body_text)
      @title = renderer.title
    end

    def data
      @data ||= open(@name.filename, "r:UTF-8").read
    end

    def body_and_head_text
      m = /^(.+?)\-\-\-\-(.+)/m.match(data)
      first, second = m[1], m[2]
      return { :head => first, :body => second } if first and second
      return { :head => nil,   :body => first  }
    end

    def body_text() @body_text ||= body_and_head_text[:body]; end
    def head_text() @head_text ||= body_and_head_text[:head]; end
  end

  class Name
    def to_note
      Note.new(self)
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
