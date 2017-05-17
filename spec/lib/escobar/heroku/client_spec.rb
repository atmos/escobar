require "spec_helper"

RSpec.describe Escobar::Heroku::Client do
  let(:client) { Escobar::Heroku::Client.new("123") }
  it "should rescue timeout errors" do
    stub_request(:get, "https://api.heroku.com/account").to_timeout
    expect do
      client.get("/account")
    end.to raise_error(Escobar::Client::TimeoutError)
  end

  it "should rescue timeout errors" do
    stub_request(:get, "https://api.heroku.com/account")
      .to_raise(Net::OpenTimeout)
    expect do
      client.get("/account")
    end.to raise_error(Escobar::Client::TimeoutError)
  end

  it "should raise on unauthorized error" do
    stub_request(:get, "https://api.heroku.com/account")
      .to_return(body: {}.to_json, status: 401)
    expect do
      client.get("/account")
    end.to raise_error(Escobar::Client::Error::Unauthorized)
  end

  it "should raise on invalid two factor error" do
    stub_request(:get, "https://api.heroku.com/account")
      .to_return(body: { id: "two_factor" }.to_json, status: 401)
    expect do
      client.get("/account")
    end.to raise_error(Escobar::Client::Error::SecondFactor)
  end

  it "should correctly handle response from a Faraday ClientError" do
    faraday_error = Faraday::Error::ClientError.new(
      "message",
      body: "body",
      headers: {
        something: true
      },
      status: 502
    )
    stub_request(:get, "https://api.heroku.com/account")
      .to_raise(faraday_error)
    expect { client.get("/account") }
      .to raise_error(Escobar::Client::HTTPError) do |e|
      expect(e.body).to eql("body")
      expect(e.headers).to eql(something: true)
      expect(e.status).to eql(502)
    end
  end
end
