require_relative "../../../spec_helper"

describe Escobar::Heroku::App do
  let(:id) { "4c18c922-6eee-451c-b7c6-c76278652ccc" }
  let(:name) { "slash-heroku" }
  let(:client) { Escobar::Client.from_environment }
  let(:pipeline) { Escobar::Heroku::Pipeline.new(client, id, name) }
  let(:app) { pipeline.environments["production"].first.app }

  before do
    stub_heroku_response("/pipelines")

    pipeline_path = "/pipelines/#{id}"
    stub_heroku_response(pipeline_path)
    stub_heroku_response("#{pipeline_path}/pipeline-couplings")
    stub_heroku_response("/apps/b0deddbf-cf56-48e4-8c3a-3ea143be2333")
    stub_kolkrabbi_response("#{pipeline_path}/repository")
  end

  it "handle preauthorization success" do
    expect(app.name).to eql("slash-heroku-production")

    path = "/apps/b0deddbf-cf56-48e4-8c3a-3ea143be2333/pre-authorizations"
    stub_request(:put, "https://api.heroku.com#{path}")
      .with(headers: default_heroku_headers)
      .to_return(
        status: 200, body: fixture_data("api.heroku.com#{path}")
      )
    expect(app.preauth("867530")).to eql(true)
  end

  it "handle preauthorization failure" do
    expect(app.name).to eql("slash-heroku-production")

    path = "/apps/b0deddbf-cf56-48e4-8c3a-3ea143be2333/pre-authorizations"
    stub_request(:put, "https://api.heroku.com#{path}")
      .with(headers: default_heroku_headers)
      .to_return(
        status: 200, body: fixture_data("api.heroku.com#{path}-failed")
      )
    expect(app.preauth("867530")).to eql(false)
  end

  it "handles locked applications" do
    expect(app.name).to eql("slash-heroku-production")

    path = "/apps/b0deddbf-cf56-48e4-8c3a-3ea143be2333/config-vars"
    stub_request(:get, "https://api.heroku.com#{path}")
      .with(headers: default_heroku_headers)
      .to_return(status: 403, body: { id: "two_factor" }.to_json)
    expect(app).to be_locked
  end

  it "handles unlocked applications" do
    expect(app.name).to eql("slash-heroku-production")

    path = "/apps/b0deddbf-cf56-48e4-8c3a-3ea143be2333/config-vars"
    stub_request(:get, "https://api.heroku.com#{path}")
      .with(headers: default_heroku_headers)
      .to_return(status: 200, body: { "RACK_ENV": "production" }.to_json)
    expect(app).to_not be_locked
  end

  it "has a unique cache key" do
    expect(app.cache_key)
      .to eql("escobar-app-b0deddbf-cf56-48e4-8c3a-3ea143be2333")
  end

  it "has a log url" do
    expect(app.log_url)
      .to eql("https://dashboard.heroku.com/apps/slash-heroku-production/logs")
  end

  it "detects direct to drain logging enabled" do
    path = "/apps/b0deddbf-cf56-48e4-8c3a-3ea143be2333/log-drains"
    failure_message = {
      id: "forbidden",
      message: "This Private Space uses direct logging which " \
               "is incompatible with this feature."
    }
    stub_request(:get, "https://api.heroku.com#{path}")
      .with(headers: default_heroku_headers)
      .to_return(status: 403, body: failure_message.to_json)

    expect(app).to be_direct_to_drain
  end

  it "detects log drains are enanled" do
    path = "/apps/b0deddbf-cf56-48e4-8c3a-3ea143be2333/log-drains"
    stub_request(:get, "https://api.heroku.com#{path}")
      .with(headers: default_heroku_headers)
      .to_return(status: 200, body: [].to_json)
    expect(app).to_not be_direct_to_drain
  end

  it "detects log drains token if present" do
    path = "/apps/b0deddbf-cf56-48e4-8c3a-3ea143be2333/log-drains"
    response = [
      {
        addon: nil,
        created_at: "2016-09-19T13:03:13Z",
        id: "g619cef4-4428-4e90-8668-aed85f8d9090",
        token: "abcdef",
        updated_at: "2016-09-19T13:03:13Z",
        url: "https://logs.herokai.com/logs"
      }
    ]
    stub_request(:get, "https://api.heroku.com#{path}")
      .with(headers: default_heroku_headers)
      .to_return(status: 200, body: response.to_json)
    expect(app).to_not be_direct_to_drain
    expect(app.drain_token).to eql("abcdef")
  end

  it "lists releases" do
    path = "/apps/b0deddbf-cf56-48e4-8c3a-3ea143be2333/releases"
    stub_request(:get, "https://api.heroku.com#{path}")
      .with(headers: default_heroku_headers)
      .to_return(
        status: 200, body: fixture_data("api.heroku.com#{path}")
      )
    expect(app.releases.size).to eql(25)
  end
end
