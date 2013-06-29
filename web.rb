# encoding: utf-8

require 'sinatra'
require 'wit'
require 'liquid'

# FIXME: should be done only on production
set :reload_template, true

published_book = Wit::Notebook.new(File.join(File.dirname(__FILE__), "t"))
thinking_book = Wit::Notebook.new(File.join(File.dirname(__FILE__), "t"), thinking: true)

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
