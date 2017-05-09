require_relative "../../../spec_helper"

describe Escobar::Heroku::Build do
  let(:id) { "4c18c922-6eee-451c-b7c6-c76278652ccc" }
  let(:name) { "slash-heroku" }
  let(:client) { Escobar::Client.from_environment }
  let(:pipeline) { Escobar::Heroku::Pipeline.new(client, id, name) }
  let(:app) { pipeline.environments["production"].first.app }

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

  it "handles build success" do
    expect(app.name).to eql("slash-heroku-production")

    build = Escobar::Heroku::Build.new(
      client, app.id, "b80207dc-139f-4546-aedc-985d9cfcafab"
    )
    build.github_url = \
      "https://api.github.com/repos/atmos/slash-heroku/deployments/9876543210"

    expect(build.info).to_not be_empty
    expect(build.id).to eql("b80207dc-139f-4546-aedc-985d9cfcafab")
    expect(build.status).to eql("succeeded")
    expect(build.repository).to eql("atmos/slash-heroku")
    expect(build.dashboard_build_output_url)
      .to eql(
        "https://dashboard.heroku.com/apps/slash-heroku-production/activity/" \
        "builds/b80207dc-139f-4546-aedc-985d9cfcafab"
      )
  end

  it "handles mixed case github url" do
    build = Escobar::Heroku::Build.new(
      client, app.id, "b80207dc-139f-4546-aedc-985d9cfcafab"
    )

    build.github_url = "https://api.github.com/repos/HEROKU/Slash-Heroku/deployments/9876543210" # rubocop:disable LineLength
    expect(build.repository).to eql("HEROKU/Slash-Heroku")
  end
end
