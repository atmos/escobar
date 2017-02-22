require "spec_helper"

RSpec.describe Escobar::Heroku::Client do
  let(:client) { Escobar::Heroku::Client.new("123") }
  it "should rescue timeout errors" do
    expect(client.client).to receive(:get).and_raise(Net::OpenTimeout)
    expect do
      client.get("/account")
    end.to raise_error(Escobar::Client::TimeoutError)
  end

  it "should correctly handle response from a Faraday ClientError" do
    faraday_error = Faraday::Error::ClientError.new("message", {
      body: "body",
      headers: { something: true },
      status: 502
    })
    expect(client.client).to receive(:get).and_raise(faraday_error)
    expect do
      client.get("/account")
    end.to raise_error(Escobar::Client::HTTPError) do |e|
      expect(e.body).to eql("body")
      expect(e.headers).to eql({something: true})
      expect(e.status).to eql(502)
    end
  end
end
