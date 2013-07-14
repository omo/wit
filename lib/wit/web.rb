# encoding: utf-8

require 'sinatra/base'
require 'liquid'
require 'wit/notebook'
require 'wit/repo'

module Wit
  class Web < Sinatra::Base
    def repo
      @@repo ||= Wit::Repo.new(settings.repopath, settings.repourl)
    end

    def published_book
      @@published_book ||= repo.published_book
    end

    def thinking_book
      @@thinking_book ||= repo.thinking_book
    end

    get '/' do
      note = published_book.cover
      p note.body
      liquid :cover, layout: nil, locals: { note: note, title: note.title }
    end

    get '/latest' do
      if settings.environment == :test
        notes = thinking_book.latest_note_names.take(10).map { |name| name.to_note }
        liquid :latest, layout: :layout, locals: { notes: notes }
      end
    end

    get '/sync' do
      liquid :sync, layout: :layout
    end

    post '/sync' do
      repo.sync
      "done"
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
