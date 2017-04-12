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

  # rubocop:disable Metrics/LineLength
  it "can promote a pipeline" do
    stub_heroku_response("/apps/760bc95e-8780-4c76-a688-3a4af92a3eee")
    stub_heroku_response("/apps/760bc95e-8780-4c76-a688-3a4af92a3eee/releases")
    stub_heroku_response("/apps/760bc95e-8780-4c76-a688-3a4af92a3eee/releases/715b6e1d-542b-40e1-9c7b-3d3128e78873")
    stub_heroku_response("/apps/760bc95e-8780-4c76-a688-3a4af92a3eee/slugs/c782eba3-db0f-44cd-a8cb-a7a3d41ef831")

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

    releases = pipeline.promote(app, targets, "production")
    expect(releases).to_not be_empty
    expect(releases.first.status).to eql("succeeded")
  end

  it "errors if 2fa is required" do
    stub_heroku_response("/apps/760bc95e-8780-4c76-a688-3a4af92a3eee")
    stub_heroku_response("/apps/760bc95e-8780-4c76-a688-3a4af92a3eee/releases")
    stub_heroku_response("/apps/760bc95e-8780-4c76-a688-3a4af92a3eee/releases/715b6e1d-542b-40e1-9c7b-3d3128e78873")
    stub_heroku_response("/apps/760bc95e-8780-4c76-a688-3a4af92a3eee/slugs/c782eba3-db0f-44cd-a8cb-a7a3d41ef831")

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

    response = fixture_data("api.heroku.com/failed-2fa")
    stub_request(:post, "https://api.heroku.com/pipeline-promotions")
      .with(headers: default_heroku_headers)
      .to_return(status: 403, body: response, headers: {})

    # Create failed statuses
    response = fixture_data("api.github.com/repos/atmos/slash-heroku/deployments/22062424/statuses/failed-1")
    stub_request(:post, "https://api.github.com/repos/atmos/slash-heroku/deployments/22062424/statuses")
      .with(headers: default_github_headers)
      .to_return(status: 200, body: response, headers: {})

    expect do
      pipeline.promote(app, targets, "production")
    end.to raise_error(Escobar::Heroku::PipelinePromotion::RequiresTwoFactorError)
  end

  it "errors if source application is failing tests" do
    stub_heroku_response("/apps/760bc95e-8780-4c76-a688-3a4af92a3eee")
    stub_heroku_response("/apps/760bc95e-8780-4c76-a688-3a4af92a3eee/releases")
    stub_heroku_response("/apps/760bc95e-8780-4c76-a688-3a4af92a3eee/releases/715b6e1d-542b-40e1-9c7b-3d3128e78873")
    stub_heroku_response("/apps/760bc95e-8780-4c76-a688-3a4af92a3eee/slugs/c782eba3-db0f-44cd-a8cb-a7a3d41ef831")

    response = fixture_data("api.github.com/repos/atmos/slash-heroku/index")
    stub_request(:get, "https://api.github.com/repos/atmos/slash-heroku")
      .with(headers: default_github_headers)
      .to_return(status: 200, body: response, headers: {})

    response = fixture_data("api.github.com/repos/atmos/slash-heroku/branches/master")
    stub_request(:get, "https://api.github.com/repos/atmos/slash-heroku/branches/master")
      .with(headers: default_github_headers)
      .to_return(status: 200, body: response, headers: {})

    response = fixture_data("api.github.com/repos/atmos/slash-heroku/required_contexts")
    stub_request(:post, "https://api.github.com/repos/atmos/slash-heroku/deployments")
      .with(headers: default_github_headers)
      .to_return(status: 409, body: response, headers: {})

    response = fixture_data("api.heroku.com/failed-2fa")
    stub_request(:post, "https://api.heroku.com/pipeline-promotions")
      .with(headers: default_heroku_headers)
      .to_return(status: 403, body: response, headers: {})

    expect do
      pipeline.promote(app, targets, "production")
    end.to raise_error(Escobar::Heroku::PipelinePromotion::MissingContextsError)
  end
  # rubocop:enable Metrics/LineLength
end
