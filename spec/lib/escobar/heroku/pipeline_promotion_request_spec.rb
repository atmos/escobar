require_relative "../../../spec_helper"

describe Escobar::Heroku::PipelinePromotionRequest do
  let(:id) { "4c18c922-6eee-451c-b7c6-c76278652ccc" }
  let(:name) { "slash-heroku" }
  let(:client) { Escobar::Client.from_environment }
  let(:pipeline) { Escobar::Heroku::Pipeline.new(client, id, name) }
  let(:app) { pipeline.environments["staging"].first.app }
  let(:targets) { pipeline.environments["production"].map(&:app) }

  before do
    stub_heroku_response("/pipelines")

    pipeline_path = "/pipelines/#{id}"
    stub_heroku_response(pipeline_path)
    stub_heroku_response("#{pipeline_path}/pipeline-couplings")
    stub_heroku_response("/apps/b0deddbf-cf56-48e4-8c3a-3ea143be2333")
    stub_kolkrabbi_response("#{pipeline_path}/repository")
  end

  it "can promote a pipeline" do
    stub_heroku_response("/apps/760bc95e-8780-4c76-a688-3a4af92a3eee")

    response = fixture_data("api.github.com/repos/atmos/slash-heroku/index")
    stub_request(:get, "https://api.github.com/repos/atmos/slash-heroku")
      .with(headers: default_github_headers)
      .to_return(status: 200, body: response, headers: {})

    response = fixture_data("api.github.com/repos/atmos/slash-heroku/branches/master")
    stub_request(:get, "https://api.github.com/repos/atmos/slash-heroku/branches/master")
      .with(headers: default_github_headers)
      .to_return(status: 200, body: response, headers: {})

    response = fixture_data("api.github.com/repos/atmos/slash-heroku/deployments/22062424")
    stub_request(:post, "https://api.github.com/repos/atmos/slash-heroku/deployments")
      .with(headers: default_github_headers)
      .to_return(status: 200, body: response, headers: {})

    response = fixture_data("api.heroku.com/pipeline-promotions/5cf65076-74be-4335-9387-26ef2c08678f")
    stub_request(:post, "https://api.heroku.com/pipeline-promotions")
      .with(headers: default_heroku_headers)
      .to_return(status: 200, body: response, headers: {})

    response = fixture_data("api.heroku.com/pipeline-promotions/5cf65076-74be-4335-9387-26ef2c08678f/promotion-targets")
    stub_request(:get, "https://api.heroku.com/pipeline-promotions/5cf65076-74be-4335-9387-26ef2c08678f/promotion-targets")
      .with(headers: default_heroku_headers)
      .to_return(status: 200, body: response, headers: {})

    response = fixture_data("api.heroku.com/apps/b0deddbf-cf56-48e4-8c3a-3ea143be2333/releases/23fe935d-88c8-4fd0-b035-10d44f3d9059")
    stub_request(:get, "https://api.heroku.com/apps/b0deddbf-cf56-48e4-8c3a-3ea143be2333/releases/23fe935d-88c8-4fd0-b035-10d44f3d9059")
      .with(headers: default_heroku_headers)
      .to_return(status: 200, body: response, headers: {})

    response = fixture_data("api.heroku.com/apps/b0deddbf-cf56-48e4-8c3a-3ea143be2333/slugs/c782eba3-db0f-44cd-a8cb-a7a3d41ef831")
    stub_request(:get, "https://api.heroku.com/apps/b0deddbf-cf56-48e4-8c3a-3ea143be2333/slugs/c782eba3-db0f-44cd-a8cb-a7a3d41ef831")
      .with(headers: default_heroku_headers)
      .to_return(status: 200, body: response, headers: {})

    response = fixture_data("api.github.com/repos/atmos/slash-heroku/deployments/22062424/statuses/pending-1")
    stub_request(:post, "https://api.github.com/repos/atmos/slash-heroku/deployments/22062424/statuses")
      .with(headers: default_github_headers)
      .to_return(status: 200, body: response, headers: {})

    releases = pipeline.promote(app, targets, "production", false, {})
    expect(releases).to_not be_empty
  end
end
