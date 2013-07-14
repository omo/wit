
#require File.join(File.dirname(__FILE__), "../web.rb")
require 'rspec'
require 'rack/test'
require 'wit/web'

module WitWebTesting
  # From http://www.sinatrarb.com/testing.html
  include Rack::Test::Methods

  class T < Wit::Web
    set(:repopath, File.join(File.dirname(__FILE__), "../testrepo/t"))
  end

  def app() T; end
end

Wit::Web.enable(:raise_errors)
Wit::Web.set(:environment, :test)

describe "THe web app" do
  include WitWebTesting
  #app.enable(:raise_errors)
  #app.set(:environment, :test)

  it "has index apge" do
    get "/latest"
    last_response.should be_ok
  end
end

describe "The latest note" do
end

describe "The article note" do
  include WitWebTesting

  it "returns formatted content" do
    get "/2012/01/02/1234-hello"
    last_response.should be_ok
    html = Nokogiri::HTML(last_response.body)
    expect(html.css("h2")[0].content).to include("This is title of example note")
  end

  it "interpret missing title as 'index'" do
    get "/2012/01/02/2345"
    last_response.should be_ok
    html = Nokogiri::HTML(last_response.body)
    expect(html.css("h2")[0].content).to include("This is title of an index page")
  end

  it "hides unpublished note" do
    get "/2012/01/02/0123-fuh"
    expect(last_response.status).to eq(404)
  end

  it "doesn't find non-existing note" do
    get "/2001/01/02/0123-fuh"
    expect(last_response.status).to eq(404)
  end

  it "rejects malformced path" do
    get "/foo/bar/baz/0123-fuh"
    expect(last_response.status).to eq(404)
  end

  # XXX: Should test not found case
end
