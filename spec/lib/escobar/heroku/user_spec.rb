require "spec_helper"

RSpec.describe Escobar::Heroku::User do
  let(:id) { "4c18c922-6eee-451c-b7c6-c76278652ccc" }
  let(:client) { Escobar::Client.from_environment }
  let(:user) { Escobar::Heroku::User.new(client.heroku) }

  it "can view the app" do
    stub_request(:put, "https://api.heroku.com/users/~/capabilities")
      .with(headers: default_heroku_headers("3.capabilities"))
      .to_return(
        status: 200, body: fixture_data("api.heroku.com/capabilities/can_view")
      )

    expect(user.can_view_app?(id)).to be_truthy
  end

  it "cannot view the app" do
    stub_request(:put, "https://api.heroku.com/users/~/capabilities")
      .with(headers: default_heroku_headers("3.capabilities"))
      .to_return(
        status: 200, body: fixture_data("api.heroku.com/capabilities/cannot_view")
      )

    expect(user.can_view_app?(id)).to be_falsey
  end
end
