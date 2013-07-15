
require 'rspec'
require 'wit/web/auth'

describe Wit::AuthHelper do
  context do
    before(:each) do 
      settings = Struct.new(:github_client_id).new
      settings.github_client_id = "testcid"
      @target = Wit::AuthHelper.new(settings)
    end

    it "generates redirect url" do
      actual = @target.redirect_uri("http://example.com")
      expect(actual).to eq("https://github.com/login/oauth/authorize?client_id=testcid&redirect_uri=http%3A%2F%2Fwit.flakiness.es%2F%7E%2Fauthback%3Ffrom%3Dhttp%253A%252F%252Fexample.com")
    end
  end
end

# http://wit.flakiness.es/~/authback?code=33c60522b092bef72746&from=http%3A%2F%2Flocalhost%3A9292%2F~%2F2013%2F07%2F14%2F2235-webhook
