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

  it "has a unique cache key" do
    pending "oh well"
    releases = pipeline.promote(app, targets, "production", false, {})
    expect(releases).to_not be_empty
  end
end
