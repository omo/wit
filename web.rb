# encoding: utf-8

require 'sinatra'
require 'wit'
require 'liquid'

# FIXME: should be done only on production
set :reload_template, true

book = Wit::Notebook.new(File.join(File.dirname(__FILE__), "t"))

get '/' do
  notes = book.latest_note_names.take(10).map { |name| name.to_note }
  liquid :latest, layout: :layout, locals: { notes: notes }
end

get '/:yyyy/:mm/:dd/:hhmm-:title' do
  name = book.name_from_components(params[:yyyy], params[:mm], params[:dd], params[:hhmm], params[:title], :md)
  liquid :note, layout: :layout, locals: { note: name.to_note }
end

get '/:yyyy/:mm/:dd/:hhmm' do
  name = book.name_from_components(params[:yyyy], params[:mm], params[:dd], params[:hhmm], nil, :md)
  liquid :note, layout: :layout, locals: { note: name.to_note }
end

