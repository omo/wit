
#require File.join(File.dirname(__FILE__), "../web.rb")
require 'rspec'
require 'rack/test'
require 'wit/web'

module WitWebTesting
  # From http://www.sinatrarb.com/testing.html
  include Rack::Test::Methods

  class T < Wit::Web
    set(:repopath, File.join(File.dirname(__FILE__), "../testrepo"))
    set(:repourl, "https://github.com/omo/whatever")
  end

  T.enable(:raise_errors)
  T.set(:environment, :test)

  def app() T; end
end

describe "The web app" do
  include WitWebTesting

  it "has latest page" do
    get "/latest"
    last_response.should be_ok
  end

  it "has cover page" do
    get "/"
    last_response.should be_ok
    html = Nokogiri::HTML(last_response.body)
    expect(html.css("h2")[0].content).to include("The Cover")
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

  it "accepts hyphen in the title" do
    get "/2013/06/01/1234-how-are-you"
    last_response.should be_ok
    html = Nokogiri::HTML(last_response.body)
    expect(html.css("h2")[0].content).to include("How Are You?")
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
