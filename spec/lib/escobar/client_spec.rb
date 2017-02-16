require_relative "../../spec_helper"

describe Escobar::Client do
  let(:client) { Escobar::Client.from_environment }

  before do
    stub_heroku_response("/pipelines")
  end

  describe "pipelines" do
    it "gets a list of available pipeline deployments" do
      expect(client.pipelines.size).to eql(2)
      expect(client.app_names).to eql(["hubot", "slash-heroku"])
      expect(client["hubot"]).to_not be_nil
      expect(client["slash-heroku"]).to_not be_nil
    end
  end

  # rubocop:disable Metrics/LineLength
  describe "multi-environment pipelines" do
    it "loads basic information about your apps from pipelines" do
      stub_heroku_response("/apps/27bde4b5-b431-4117-9302-e533b887faaa")
      stub_heroku_response("/apps/b0deddbf-cf56-48e4-8c3a-3ea143be2333")
      stub_heroku_response("/pipelines/531a6f90-bd76-4f5c-811f-acc8a9f4c111")
      stub_heroku_response("/pipelines/531a6f90-bd76-4f5c-811f-acc8a9f4c111/pipeline-couplings")
      stub_kolkrabbi_response("/pipelines/531a6f90-bd76-4f5c-811f-acc8a9f4c111/repository")

      pipeline = client["hubot"]
      expect(pipeline.name).to eql("hubot")
      expect(pipeline.github_repository).to eql("atmos/hubot")
      expect(pipeline.couplings.size).to eql(1)
      expect(pipeline.couplings.first.name).to eql("hubot")
      expect(pipeline.couplings.first.stage).to eql("production")
    end
  end

  describe "single-environment pipelines" do
    it "loads basic information about your apps from pipelines" do
      stub_heroku_response("/apps/27bde4b5-b431-4117-9302-e533b887faaa")
      stub_heroku_response("/apps/b0deddbf-cf56-48e4-8c3a-3ea143be2333")
      stub_heroku_response("/pipelines/4c18c922-6eee-451c-b7c6-c76278652ccc")
      stub_heroku_response("/pipelines/4c18c922-6eee-451c-b7c6-c76278652ccc/pipeline-couplings")
      stub_kolkrabbi_response("/pipelines/4c18c922-6eee-451c-b7c6-c76278652ccc/repository")

      pipeline = client["slash-heroku"]
      expect(pipeline.name).to eql("slash-heroku")
      expect(pipeline.github_repository).to eql("atmos/slash-heroku")
      expect(pipeline.couplings.size).to eql(2)
      expect(pipeline.couplings.first.stage).to eql("production")
      expect(pipeline.couplings.last.stage).to eql("staging")
    end
  end
  # rubocop:enable Metrics/LineLength

  it "wraps http exceptions well" do
    err = ArgumentError.new("Missing some stuff")

    response_body    = { id: "two_factor", message: "Missing 2fa" }.to_json
    response_headers = { offset: "1" }
    stub_request(:get, "https://heroku.com").to_return(
      status: 403, body: response_body, headers: response_headers
    )

    response = Faraday.get "https://heroku.com"

    exception = Escobar::Client::HTTPError.from_response(err, response)
    expect(exception.status).to eql(403)
    expect(exception.body).to eql(
      "{\"id\":\"two_factor\",\"message\":\"Missing 2fa\"}"
    )
  end
end
