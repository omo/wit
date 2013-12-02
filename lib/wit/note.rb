# encoding: utf-8

require 'erb'
require 'fileutils'
require 'liquid'
require 'psych'
require 'redcarpet'
require 'wit/base'
require 'wit/name'

module Wit
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

  class NoteContent < Struct.new(:data, :body_text, :head_text, :head, :body, :title); end

  # FIXME: should have its own file
  class Note
    liquid_methods :body, :url, :title, :title_or_untitled, :last_digits
    attr_reader :name

    def initialize(name)
      # FIXME: ensure if it is header-prepended markdown
      @content = NoteContent.new
      @name = name
    end

    def clear() @content = NoteContent.new; end

    def exist?() name.exist?; end
    def url() name.url; end
    def published?() head["publish"]; end

    def head
      @content.head ||= Psych.load(head_text || '')
    end

    def head_or_empty
      exist?() ? head : {}
    end

    def body
      render_if_needed
      @content.body
    end

    def title
      render_if_needed
      @content.title
    end

    def title_or_untitled
      title or "(Untitled)"
    end

    def last_digits
      last = name.components.digits.last
      last[0 ... 2] + ":" + last[2 ... 4]
    end

    def digits
      name.components.digits
    end

BOILERPLATE = ERB.new(<<EOF
publish: false
----
<% if title %>
# <%= title %>
<% end %>
EOF
)

    def self.make_boilerplate(title=nil)
      BOILERPLATE.result(binding)
    end

    def write
      raise "There is no content to write!" unless @content.data
      overwrite(@content.data)
      clear
    end

    def write_boilerplate(title=nil)
      raise "The file #{@name.filename} is already exist!" if exist?
      overwrite(Note.make_boilerplate(title))
      clear
    end

    def update(head, body_md)
      old_head = self.head_or_empty
      clear
      @content.data = Psych.dump(old_head.merge(head)) + "\n----\n" + body_md
    end

    def to_api_response
      { "publish" => published?, "body" => body_text, "title" => title }
    end

    private

    def overwrite(data)
      FileUtils.makedirs(File.dirname(@name.filename))
      open(@name.filename, "w:UTF-8") { |f| f.write data }
    end
    
    def render_if_needed
      return if @content.body
      render
    end

    def render
      raise if @content.body # Should be guarded by render_if_needed
      opts = { :autolink => true, :space_after_headers => true }
      renderer = NoteRenderer.new
      md = Redcarpet::Markdown.new(renderer, opts)
      @content.body  = md.render(body_text)
      @content.title = renderer.title
    end

    def data
      @content.data ||= open_or_create
    end

    def open_or_create
      if @name.exist?
        open(@name.filename, "r:UTF-8") { |f| f.read }
      else
        Note.make_boilerplate
      end
    end

    def body_and_head_text
      m = /^(.+?)\-\-\-\-\n(.+)/m.match(data)
      first, second = m[1], m[2]
      return { :head => first, :body => second } if first and second
      return { :head => nil,   :body => first  }
    end

    def body_text() @content.body_text ||= body_and_head_text[:body]; end
    def head_text() @content.head_text ||= body_and_head_text[:head]; end
  end

  class Name
    def to_note
      Note.new(self)
    end
  end

  class NoteName < Name
    class NoteComponents < Struct.new(:digits, :title)
      def to_u
        # FIXME: take care of non-md type/suffix
        if self.title
          "/" + self.digits.join("/") + "-" + self.title
        else
          "/" + self.digits.join("/")
        end
      end
    end

    def walk(delta)
      # FIXME: impl
      raise if 1 < delta.abs
      # FIXME: handle non-md file
      siblings = Dir.glob(File.join(File.dirname(@filename), "*.md")).sort
      index = siblings.find_index(@filename)
      return NoteName.new(siblings[index + delta]) if (0 ... siblings.size).cover?(index + delta)

      dirdelta = delta # FIXME: Won't be true for |1 < delta.abs|
      dir = File.dirname(@filename)
      dirsibs = Dir.glob(File.join(File.dirname(dir), "*")).sort
      dirindex = dirsibs.find_index(dir)
      cursor = dirindex + dirdelta
      while true
        return nil unless (0 ... dirsibs.size).cover?(cursor)
        cousins = Dir.glob(File.join(dirsibs[cursor], "*.md")).sort
        return NoteName.new(0 < delta ? cousins.first : cousins.last) unless cousins.empty?
        cursor += dirdelta
      end
    end

    def components() @components ||= make_components; end
    def url() components.to_u; end

    private
    
    def make_components
      # FIXME: take care of non-md type/suffix
      components = File.basename(@filename).gsub(/\..+$/, "").split("_")
      if components[-1] == "index"
        NoteComponents.new(components[0 .. -2], nil)
      else
        NoteComponents.new(components[0 .. -2], components[-1])
      end
    end
  end

  class PageName < Name
    def url() "/+/#{label}"; end
    def label() @label ||= make_label; end

    def make_label
      File.basename(@filename).gsub(/\..+$/, "")
    end
  end
end
