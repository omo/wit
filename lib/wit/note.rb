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

  # FIXME: should have its own file
  class Note
    liquid_methods :body, :url, :title, :title_or_untitled, :last_digits
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
end
