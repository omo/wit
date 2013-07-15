
require 'rspec'
require 'rack/test'
require 'wit/web'

module WitWebTesting
  # From http://www.sinatrarb.com/testing.html
  include Rack::Test::Methods

  class T < Wit::Web
    set(:repopath, File.join(File.dirname(__FILE__), "../testrepo"))
    set(:repourl, "https://github.com/omo/whatever")
    set(:github_client_id, "testcid")
    set(:github_client_secret, "testsecret")
    set(:github_login, "octocat")
    set(:environment, :test)
    enable(:sessions) # Real session is enabled in config.ru
    enable(:raise_errors)
  end

  def app() @app ||= T.new; end
end

describe "The web app" do
  include WitWebTesting

  it "has latest page" do
    get "/~/latest"
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

  it "Should handle more than one splitter" do
    get "/2013/06/01/2345-split"
    last_response.should be_ok
    html = Nokogiri::HTML(last_response.body)
    expect(html.to_s).to include("This should be visible.")
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

describe "The sync" do
  include WitWebTesting

  it "shoud be served" do
    get "/sync"
    html = Nokogiri::HTML(last_response.body)
    expect(html.css("input").size).to eq(1)
  end
end

describe "The Auth" do
  include WitWebTesting
  it "should handle auth callback" do
    get "/~/authback?code=testcode&from=http%3A%2F%2Flocalhost%3A9292%2F~%2F2013%2F07%2F14%2F2235-webhook"
    expect(last_response.location).to eq("http://localhost:9292/~/2013/07/14/2235-webhook")
  end
end
