require_relative "../../../spec_helper"

describe Escobar::Heroku::ConfigVars do
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

  it "fetches environmental variables on sucess" do
    path = "/apps/b0deddbf-cf56-48e4-8c3a-3ea143be2333/config-vars"
    stub_request(:get, "https://api.heroku.com#{path}")
      .with(headers: default_heroku_headers)
      .to_return(
        status: 200, body: fixture_data("api.heroku.com#{path}")
      )

    config_vars = app.config_vars
    expect(config_vars["LANG"]).to eql("en_US.UTF-8")
    expect(config_vars["RACK_ENV"]).to eql("production")
    expect(config_vars["NOT_FOUND"]).to be nil
  end

  it "returns an empty hash on 2fa protected" do
    path = "/apps/b0deddbf-cf56-48e4-8c3a-3ea143be2333/config-vars"
    stub_request(:get, "https://api.heroku.com#{path}")
      .with(headers: default_heroku_headers)
      .to_return(
        status: 403, body: fixture_data("api.heroku.com/failed-2fa")
      )

    config_vars = app.config_vars
    expect(config_vars.values).to be_empty
  end
end
