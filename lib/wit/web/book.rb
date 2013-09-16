# encoding: utf-8

require 'sinatra/base'
require 'json'
require 'liquid'
require 'wit/repo'
require 'wit/web/helpers'

module Wit
  class BookWeb < Sinatra::Base
    include RepoOwnable, ApiServable

    def book() raise "Should be overriden!"; end
    def url_prefix() book.thinking?() ? "/~" : ""; end

    def note_view_locals(note)
      { note: note, title: note.title, prefix: url_prefix, thinking: book.thinking?, edit_url: url_prefix + "/edit" + note.url }
    end

    def index_view_locals
      { months: book.months, prefix: url_prefix, thinking: book.thinking? }
    end

    get '/' do
      note = book.cover
      #liquid :cover, layout: :index, locals: { note: note, months: book.months, title: note.title, prefix: url_prefix, thinking: book.thinking? }
      liquid :cover, layout: :index, locals: index_view_locals.merge({ note: note, title: note.title,  })
    end


    get '/+/:label' do
      name = book.page_name_from_label(params[:label])
      note = book.to_note(name)
      liquid :note, layout: :layout, locals: note_view_locals(note)
    end

    get '/pages' do
      names = book.page_names
      notes = book.to_notes(names)
      liquid :pages, layout: :index, locals: index_view_locals.merge({ notes: notes })
    end

    get '/:yyyy/:mm' do
      m = book.month_from_components(params[:yyyy], params[:mm])
      notes = book.to_notes(m.names)
      notes_per_day = notes.inject({}) do |a, i|
        (a[i.digits[-2]] ||= []) << i
        a
      end.sort

      notes_per_day.each { |k,v| v.sort! { |x, y| x.url <=> y.url } }

      liquid :month, layout: :index, locals: { months: book.months, month: m, notes: notes_per_day, prefix: url_prefix, thinking: book.thinking? }
    end

    get '/:yyyy/:mm/:dd/:hhmmtitle.json' do
      should_be_api_request
      name = book.md_name_from_components(params[:yyyy], params[:mm], params[:dd], params[:hhmmtitle])
      note = book.to_note(name)
      JSON.dump(note.to_api_response)
    end

    get '/:yyyy/:mm/:dd/:hhmmtitle' do
      name = book.md_name_from_components(params[:yyyy], params[:mm], params[:dd], params[:hhmmtitle])
      note = book.to_note(name)
      locals = note_view_locals(note)
      if book.thinking?
        next_name = name.walk( 1)
        prev_name = name.walk(-1)
        locals[:up_url] = url_prefix + book.month_of(name).url
        locals[:next_url] = url_prefix + next_name.url if next_name
        locals[:prev_url] = url_prefix + prev_name.url if prev_name
      end

      liquid :note, layout: :layout, locals: locals
    end

    error Wit::Forbidden, Wit::NotFound do
      halt 404
    end
  end

  class PublishedBookWeb < BookWeb
    def book
      @@book ||= repo.published_book
    end
  end

  class ThinkingBookWeb < BookWeb
    def book
      @@book ||= repo.thinking_book
    end

    def put_note_named(name)
      publish = required_value_of("publish")
      body = required_value_of("body")
      note = book.to_note(name, { fresh: true })
      note.update({ "publish" => publish }, body)
      note.write # We don't sync here. Each client should do that.
      JSON.dump(note.to_api_response)
    end

    get '/latest' do
      if settings.environment == :test
        notes = book.latest_note_names.take(10).map { |name| name.to_note }
        liquid :latest, layout: :layout, locals: { notes: notes }
      end
    end

    # Following endpoints are APIs for editing screens

    put '/+/:label' do
      should_be_api_request
      name = book.page_name_from_label(params[:label])
      put_note_named(name)
    end

    put '/:yyyy/:mm/:dd/:hhmmtitle' do
      should_be_api_request
      name = book.md_name_from_components(params[:yyyy], params[:mm], params[:dd], params[:hhmmtitle])
      put_note_named(name)
    end

    post '/fresh' do
      should_be_api_request
      name = book.fresh_note_name(req_hash["title"])
      JSON.dump({ "url" => url_prefix + name.url })
    end

    get '/edit'  do
      liquid :edit, layout: :layout, locals: { prefix: url_prefix } 
    end

    get '/edit/*' do
      liquid :edit, layout: :layout, locals: { prefix: url_prefix }
    end
  end
end
