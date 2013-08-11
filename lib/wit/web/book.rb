# encoding: utf-8

require 'sinatra/base'
require 'json'
require 'liquid'
require 'wit/repo'
require 'wit/web/helpers'

module Wit
  class BookWeb < Sinatra::Base
    include RepoOwnable, ApiServable

    def thinking() false; end
    def book() raise "Should be overriden!"; end
    def url_prefix() book.thinking?() ? "/~" : ""; end

    get '/' do
      note = book.cover
      liquid :cover, layout: :index, locals: { note: note, months: book.months, title: note.title, prefix: url_prefix, thinking: thinking }
    end

    get '/:yyyy/:mm' do
      m = book.month_from_components(params[:yyyy], params[:mm])
      notes = book.to_notes(m.names)
      notes_per_day = notes.inject({}) do |a, i|
        (a[i.digits[-2]] ||= []) << i
        a
      end.sort

      notes_per_day.each { |k,v| v.sort! { |x, y| x.url <=> y.url } }

      liquid :month, layout: :index, locals: { months: book.months, month: m, notes: notes_per_day, prefix: url_prefix, thinking: thinking }
    end

    get '/:yyyy/:mm/:dd/:hhmmtitle' do
      name = book.md_name_from_components(params[:yyyy], params[:mm], params[:dd], params[:hhmmtitle])
      note = book.to_note(name)
      if api_request?
        JSON.dump(note.to_api_response)
      else
        edit_url = url_prefix + "/edit" + note.url
        liquid :note, layout: :layout, locals: { note: note, title: note.title, prefix: url_prefix, thinking: thinking, edit_url: edit_url }
      end
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
    def thinking()
      true
    end

    def book
      @@book ||= repo.thinking_book
    end

    get '/latest' do
      if settings.environment == :test
        notes = book.latest_note_names.take(10).map { |name| name.to_note }
        liquid :latest, layout: :layout, locals: { notes: notes }
      end
    end

    # Following endpoints are APIs for editing screens

    put '/:yyyy/:mm/:dd/:hhmmtitle' do
      should_be_api_request

      publish = required_value_of("publish")
      body = required_value_of("body")
      name = book.md_name_from_components(params[:yyyy], params[:mm], params[:dd], params[:hhmmtitle])
      note = book.to_note(name, { fresh: true })
      note.update({ "publish" => publish }, body)
      note.write # We don't sync here. Each client should do that.
      JSON.dump(note.to_api_response)
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
