require_relative "../../../spec_helper"

describe Escobar::Heroku::Dynos do
  let(:id) { "4c18c922-6eee-451c-b7c6-c76278652ccc" }
  let(:name) { "slash-heroku" }
  let(:client) { Escobar::Client.from_environment }
  let(:pipeline) { Escobar::Heroku::Pipeline.new(client, id, name) }
  let(:app) { pipeline.environments["production"].first.app }
  let(:dynos) { app.dynos }

  before do
    stub_heroku_response("/pipelines")

    pipeline_path = "/pipelines/#{id}"
    stub_heroku_response(pipeline_path)

    app_path = "/apps/b0deddbf-cf56-48e4-8c3a-3ea143be2333"
    stub_heroku_response("#{pipeline_path}/pipeline-couplings")
    stub_heroku_response(app_path)
    stub_kolkrabbi_response("#{pipeline_path}/repository")
    stub_heroku_response(
      "#{app_path}/builds/b80207dc-139f-4546-aedc-985d9cfcafab"
    )
  end

  it "knows if dynos are newer than a specific date" do
    path = "/apps/b0deddbf-cf56-48e4-8c3a-3ea143be2333/dynos"
    stub_request(:get, "https://api.heroku.com#{path}")
      .with(headers: default_heroku_headers)
      .to_return(
        status: 200, body: fixture_data("api.heroku.com#{path}")
      )

    expect(dynos).to be_newer_than(Time.parse("2017-02-05T08:03:17Z").utc)
    expect(dynos).to_not be_newer_than(Time.parse("2017-02-06T08:03:17Z").utc)

    expect(dynos).to be_running("715b6e1d-542b-40e1-9c7b-3d3128e78873")
  end
end
