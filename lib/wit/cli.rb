
require 'wit' # This is ugly but inevitable in this case.
              # Consider that cli.rb isn't part of wit library. 
require 'thor'

module Wit
  class CLI < Thor
    desc "fresh [TITLE]", "Print a filename for fresh note."
    def fresh(title=nil)
      fresh = book.fresh_note_name(title)
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

    def book
      @book ||= open_notebook
    end

    def open_notebook
      # FIXME: should be configurable
      root = File.realpath(File.join(File.dirname(__FILE__), "../../t"))
      Wit::Notebook.new(root)
    end
  end
end

