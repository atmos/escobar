require_relative "../../../spec_helper"

describe Escobar::Heroku::Release do
  let(:id) { "4c18c922-6eee-451c-b7c6-c76278652ccc" }
  let(:name) { "slash-heroku" }
  let(:client) { Escobar::Client.from_environment }
  let(:pipeline) { Escobar::Heroku::Pipeline.new(client, id, name) }
  let(:app) { pipeline.environments["production"].first.app }
  let(:build) do
    Escobar::Heroku::Build.new(
      client, app, "b80207dc-139f-4546-aedc-985d9cfcafab"
    )
  end

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

    release_path = "/apps/b0deddbf-cf56-48e4-8c3a-3ea143be2333/releases/" \
                   "23fe935d-88c8-4fd0-b035-10d44f3d9059"
    stub_heroku_response(release_path)
  end

  it "looks at a release" do
    release = Escobar::Heroku::Release.new(
      client,
      app.id,
      "b80207dc-139f-4546-aedc-985d9cfcafab",
      "23fe935d-88c8-4fd0-b035-10d44f3d9059"
    )

    expect(release.id).to eql("23fe935d-88c8-4fd0-b035-10d44f3d9059")
    expect(release.status).to eql("succeeded")
    expect(release.build.status).to eql("succeeded")
  end

  it "knows the slug ref" do
    release = Escobar::Heroku::Release.new(
      client,
      app.id,
      "b80207dc-139f-4546-aedc-985d9cfcafab",
      "23fe935d-88c8-4fd0-b035-10d44f3d9059"
    )

    stub_heroku_response(
      "/apps/#{app.id}/slugs/c782eba3-db0f-44cd-a8cb-a7a3d41ef831"
    )

    expect(release.ref).to eql("f7c319ed2be5d9de5d6bc71665101d6f49836439")
  end
end
