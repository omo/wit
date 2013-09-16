# encoding: utf-8

require 'wit' # This is ugly but inevitable in this case.
              # Consider that cli.rb isn't part of wit library. 
require 'thor'

module Wit

  class CLI < Thor
    class_option :config, :type => :string, :default => File.expand_path("~/.wit")

    desc "fresh [TITLE]", "Print a filename for fresh note."
    option :boilerplate, :type => :boolean
    def fresh(title=nil)
      title = nil if title && title.empty? # This normalization is needed since caller invoke this through shell with quotes.
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
      n = Wit::NoteName.new(name).walk(1)
      puts n ? n.filename : ""
    end

    desc "prev NAME", "Print a previous note entry of given one."
    def prev(name)
      n = Wit::NoteName.new(name).walk(-1)
      puts n ? n.filename : ""
    end

    desc "page LABEL", "Reurn the filename of specified page."
    option :boilerplate, :type => :boolean
    def page(label)
      n = book.page_name_from_label(label)
      n.to_note.write_boilerplate(label) if options[:boilerplate] and not n.exist?
      puts n ? n.filename : ""
    end

    desc "sync", "Pull then push the note repository."
    def sync
      repo.sync
    end

    private

    def config() @config ||= Config.make(options[:config]); end
    def book() @book ||= repo.thinking_book; end
    def repo() @repo ||= Wit::Repo.new(config.repopath, config.repourl); end
  end
end

