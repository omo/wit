# encoding: utf-8

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
end
