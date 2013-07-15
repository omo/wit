# encoding: utf-8

require 'sinatra/base'
require 'liquid'
require 'wit/repo'
require 'wit/web/helpers'

module Wit
  class BookWeb < Sinatra::Base
    include RepoOwnable

    def published_book
      @@published_book ||= repo.published_book
    end

    def thinking_book
      @@thinking_book ||= repo.thinking_book
    end

    get '/' do
      note = published_book.cover
      liquid :cover, layout: nil, locals: { note: note, title: note.title }
    end

    get '/latest' do
      if settings.environment == :test
        notes = thinking_book.latest_note_names.take(10).map { |name| name.to_note }
        liquid :latest, layout: :layout, locals: { notes: notes }
      end
    end

    get '/:yyyy/:mm/:dd/:hhmmtitle' do
      book = published_book
      m = /(\d+)\-(.*)/.match(params[:hhmmtitle])
      if m
        hhmm  = m[1]
        title = m[2]
        name = book.name_from_components(params[:yyyy], params[:mm], params[:dd], hhmm, title, :md)
      else
        name = book.name_from_components(params[:yyyy], params[:mm], params[:dd], params[:hhmmtitle], nil, :md)
      end
      note = book.to_note(name)
      liquid :note, layout: :layout, locals: { note: note, title: note.title }
    end

    error Wit::Forbidden, Wit::NotFound do
      halt 404
    end
  end
end
