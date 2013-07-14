# encoding: utf-8

require 'sinatra/base'
require 'wit/notebook'
require 'liquid'

module Wit
  class Web < Sinatra::Base
    def published_book
      @@published_book ||= Wit::Notebook.new(settings.repopath)
    end

    def thinking_book
      @@thinking_book ||= Wit::Notebook.new(settings.repopath, thinking: true)
    end

    get '/latest' do
      if settings.environment == :test
        notes = thinking_book.latest_note_names.take(10).map { |name| name.to_note }
        liquid :latest, layout: :layout, locals: { notes: notes }
      end
    end

    get '/:yyyy/:mm/:dd/:hhmm-:title' do
      book = published_book
      name = book.name_from_components(params[:yyyy], params[:mm], params[:dd], params[:hhmm], params[:title], :md)
      liquid :note, layout: :layout, locals: { note: book.to_note(name) }
    end

    get '/:yyyy/:mm/:dd/:hhmm' do
      book = published_book
      name = book.name_from_components(params[:yyyy], params[:mm], params[:dd], params[:hhmm], nil, :md)
      liquid :note, layout: :layout, locals: { note: book.to_note(name) }
    end

    error Wit::Forbidden, Wit::NotFound do
      halt 404
    end
  end
end
