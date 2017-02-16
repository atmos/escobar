require_relative "../../../spec_helper"

describe Escobar::Heroku::Client::HTTPError do
  it "wraps exceptions well" do
    err = ArgumentError.new("Missing some stuff")

    response_body    = { id: "two_factor", message: "Missing 2fa" }.to_json
    response_headers = { offset: "1" }
    stub_request(:get, "https://heroku.com").to_return(
      status: 403, body: response_body, headers: response_headers
    )

    response = Faraday.get "https://heroku.com"

    exception = Escobar::Heroku::Client::HTTPError.from_response(err, response)
    expect(exception.status).to eql(403)
    expect(exception.body).to eql(
      "{\"id\":\"two_factor\",\"message\":\"Missing 2fa\"}"
    )
  end
end
