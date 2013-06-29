
require File.join(File.dirname(__FILE__), "../web.rb")
require 'rspec'
require 'rack/test'

module WitWebTesting
  # From http://www.sinatrarb.com/testing.html
  include Rack::Test::Methods
  def app() Sinatra::Application; end
end

set :raise_errors, false

describe "THe web app" do
  include WitWebTesting

  it "has index apge" do
    get "/"
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

  # XXX: Should test not found case
end
