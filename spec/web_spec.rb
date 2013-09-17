
require 'rspec'
require 'rack/test'
require 'wit/web'

module WitWebTesting
  # From http://www.sinatrarb.com/testing.html
  include Rack::Test::Methods

  REPO_PATH = File.join(File.dirname(__FILE__), "../testrepo")

  class T < Wit::Web
    set(:repopath, REPO_PATH)
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
    app.enable(:disable_auth)
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

describe "The month index" do
  include WitWebTesting

  it "returns list of note links" do
    get "/2012/01"
    last_response.should be_ok
  end
end

describe "The article note" do
  include WitWebTesting

  it "returns formatted content" do
    get "/2012/01/02/1234-hello"
    last_response.should be_ok
    html = Nokogiri::HTML(last_response.body)
    expect(html.css("h2")[0].content).to include("This is title of example note")
  end

  it "returns as json" do
    header("Content-Type", "application/json")
    get "/2012/01/02/1234-hello.json"
    last_response.should be_ok
    j = JSON.parse(last_response.body)
    expect(j["body"]).to include("This is title of example note")
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

  it "has prefetch links" do
    app.enable(:disable_auth)
    get "/~/2012/01/02/1234-hello"
    last_response.should be_ok
    html = Nokogiri::HTML(last_response.body)
    expect(html.css("#prev-link")[0]["href"]).to eq("/~/2012/01/02/0123-fuh")
    expect(html.css("#next-link")[0]["href"]).to eq("/~/2012/01/02/2345")
    expect(html.css("#up-link")[0]["href"]).to eq("/~/2012/01")
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

describe "The page view and the page index" do
  include WitWebTesting
  it "shows lablelled page" do
    get "/+/Foo"
    expect(last_response.status).to eq(200)
  end

  it "returns as json" do
    header("Content-Type", "application/json")
    get "/+/Foo.json"
    last_response.should be_ok
    j = JSON.parse(last_response.body)
    expect(j["body"]).to include("Foo")
  end

  it "shows lablelled page" do
    get "/pages"
    expect(last_response.status).to eq(200)
  end
end

def to_json_str(dict)
  StringIO.new(JSON.dump(dict))
end

describe "Posting" do
  include WitWebTesting

  context do
    after(:each) do
      system("cd #{WitWebTesting::REPO_PATH} && git clean -fdq && git checkout HEAD .")
    end

    it "creates a fresh post" do
      app.enable(:disable_auth)

      path = "/~/2013/08/09/1234-hello"
      get(path)
      expect(last_response.status).to eq(404)

      header("Content-Type", "application/json")
      put(path, to_json_str("publish" => true, "body" => "Hello"))
      expect(last_response.status).to eq(200)
      res = JSON.parse(last_response.body)
      expect(res["body"]).to eq("Hello")
      expect(res["publish"]).to eq(true)
    end

    it "creates a page" do
      header("Content-Type", "application/json")
      put("/~/+/Hello", to_json_str("publish" => true, "body" => "Hello2"))
      expect(last_response.status).to eq(200)
      expect(JSON.parse(last_response.body)["body"]).to eq("Hello2")
    end

    it "makes fresh url" do
      app.enable(:disable_auth)
      header("Content-Type", "application/json")
      post("/~/fresh", to_json_str("title" => "Hello, Title"))
      expect(last_response.status).to eq(200)
      res = JSON.parse(last_response.body)
      expect(res["url"]).to end_with("hello-title")
      expect(res["url"]).to start_with("/~")
    end

    it "makes fresh url without keyword" do
      app.enable(:disable_auth)
      header("Content-Type", "application/json")
      post("/~/fresh", to_json_str("title" => ""))
      expect(last_response.status).to eq(200)
      res = JSON.parse(last_response.body)
      expect(res["url"].class).to eq(String)
    end
  end
end

describe "The sync" do
  include WitWebTesting

  it "shoud be served" do
    app.enable(:disable_auth)
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
