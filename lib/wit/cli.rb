# encoding: utf-8

require 'wit' # This is ugly but inevitable in this case.
              # Consider that cli.rb isn't part of wit library. 
require 'thor'

module Wit

  # FIXME: Should be in its own file
  class Config
    attr_reader :options

    def initialize
      @options = {}
    end

    def load(path)
      File.open(path) do |f|
        instance_eval(f.read)
      end
    end

    def self.make(path)
      created = self.new
      if true
        created.load(path) 
      else
        # TODO: Write default
      end

      created
    end

    def repopath() options[:repopath]; end
  end

  class CLI < Thor
    desc "fresh [TITLE]", "Print a filename for fresh note."
    option :boilerplate, :type => :boolean
    def fresh(title=nil)
      title = nil if title.empty? # This normalization is needed since caller invoke this through shell with quotes.
      fresh = book.fresh_note_name(title || "index")
      fresh.to_note.write_boilerplate(title) if options[:boilerplate]
      puts fresh.filename
    end

    desc "latest", "Print the name of the latest note."
    def latest
      puts book.latest_note_names.first.filename
    end

    desc "next NAME", "Print a next note entry of given one."
    def next(name)
      n = Wit::Name.new(name).walk(1)
      puts n ? n.filename : ""
    end

    desc "prev NAME", "Print a previous note entry of given one."
    def prev(name)
      n = Wit::Name.new(name).walk(-1)
      puts n ? n.filename : ""
    end

    private

    def config
      @config ||= Config.make(File.expand_path("~/.wit"))
    end

    def book
      @book ||= open_notebook
    end

    def open_notebook
      Wit::Repo.new(config.repopath).thinking_book
    end
  end
end

