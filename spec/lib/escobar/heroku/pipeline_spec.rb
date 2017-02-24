require_relative "../../../spec_helper"

describe Escobar::Heroku::Pipeline do
  let(:id) { "4c18c922-6eee-451c-b7c6-c76278652ccc" }
  let(:name) { "slash-heroku" }
  let(:client) { Escobar::Client.from_environment }

  before do
    stub_heroku_response("/pipelines")
  end

  describe "pipelines" do
    # rubocop:disable Metrics/LineLength
    it "gets a list of available pipeline deployments" do
      pipeline_path = "/pipelines/#{id}"
      stub_heroku_response(pipeline_path)
      stub_heroku_response("#{pipeline_path}/pipeline-couplings")
      stub_kolkrabbi_response("#{pipeline_path}/repository")

      response = fixture_data("api.github.com/repos/atmos/slash-heroku/index")
      stub_request(:get, "https://api.github.com/repos/atmos/slash-heroku")
        .with(headers: default_github_headers)
        .to_return(status: 200, body: response, headers: {})

      pipeline = Escobar::Heroku::Pipeline.new(client, id, name)
      expect(pipeline.github_repository).to eql("atmos/slash-heroku")
      expect(pipeline).to be_configured
      expect(pipeline.heroku_permalink)
        .to eql("https://dashboard.heroku.com/pipelines/#{id}")
      expect(pipeline.default_branch_settings_uri)
        .to eql("https://github.com/atmos/slash-heroku/settings/branches/master")

      couplings = pipeline.couplings
      expect(couplings.size).to eql(2)
      expect(couplings.first.stage).to eql("production")
      expect(couplings.last.stage).to eql("staging")
    end

    it "knows a respository is misconfigured if no github repo connected" do
      pipeline_path = "/pipelines/#{id}"
      stub_heroku_response(pipeline_path)
      stub_heroku_response("#{pipeline_path}/pipeline-couplings")

      response = { id: "not_found", message: "Not found." }.to_json
      stub_request(:get, "https://kolkrabbit.com#{pipeline_path}/repository")
        .with(headers: default_kolkrabbi_headers)
        .to_return(status: 404, body: response)

      pipeline = Escobar::Heroku::Pipeline.new(client, id, name)
      expect(pipeline).to_not be_configured
      expect(pipeline.github_repository).to be_nil

      couplings = pipeline.couplings
      expect(couplings.size).to eql(2)
      expect(couplings.first.stage).to eql("production")
      expect(couplings.last.stage).to eql("staging")
    end

    it "knows the required contexts of a pipeline" do
      pipeline_path = "/pipelines/#{id}"
      stub_heroku_response(pipeline_path)
      stub_heroku_response("#{pipeline_path}/pipeline-couplings")
      stub_kolkrabbi_response("#{pipeline_path}/repository")

      response = fixture_data("api.github.com/repos/atmos/slash-heroku/index")
      stub_request(:get, "https://api.github.com/repos/atmos/slash-heroku")
        .with(headers: default_github_headers)
        .to_return(status: 200, body: response, headers: {})
      response = fixture_data("api.github.com/repos/atmos/slash-heroku/branches/master")
      stub_request(:get, "https://api.github.com/repos/atmos/slash-heroku/branches/master")
        .with(headers: default_github_headers)
        .to_return(status: 200, body: response, headers: {})

      pipeline = Escobar::Heroku::Pipeline.new(client, id, name)
      expect(pipeline.github_repository).to eql("atmos/slash-heroku")
      expect(pipeline).to be_configured
      expect(pipeline.default_environment).to eql("staging")
      expect(pipeline.default_branch).to eql("master")
      expect(pipeline.required_commit_contexts).to eql(["continuous-integration/travis-ci/push"])
    end

    it "returns a default heroku application name to deploy for a stage" do
      pipeline_path = "/pipelines/#{id}"
      stub_heroku_response(pipeline_path)
      stub_heroku_response("#{pipeline_path}/pipeline-couplings")
      stub_heroku_response("/apps/b0deddbf-cf56-48e4-8c3a-3ea143be2333")
      stub_kolkrabbi_response("#{pipeline_path}/repository")

      pipeline = Escobar::Heroku::Pipeline.new(client, id, name)
      expect(pipeline.default_heroku_application("production").name)
        .to eql("slash-heroku-production")
    end

    it "create_deployment deploys a master branch" do
      pipeline_path = "/pipelines/#{id}"
      stub_heroku_response("/apps/b0deddbf-cf56-48e4-8c3a-3ea143be2333")
      stub_heroku_response("/apps/760bc95e-8780-4c76-a688-3a4af92a3eee")
      stub_heroku_response("/apps/760bc95e-8780-4c76-a999-3a4af92a3eee")

      stub_heroku_response(pipeline_path)
      stub_heroku_response("#{pipeline_path}/pipeline-couplings")
      stub_kolkrabbi_response("#{pipeline_path}/repository")

      stub_request(:get, "https://api.heroku.com/apps/b0deddbf-cf56-48e4-8c3a-3ea143be2333/config-vars")
        .to_return(status: 200, body: { "RACK_ENV": "production" }.to_json, headers: {})

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

      tarball_headers = {
        "Location": "https://codeload.github.com/atmos/slash-heroku/legacy.tar.gz/8115792777a8d60fcf1c5e181ce3c3bc34e5eb1b"
      }
      stub_request(:head, "https://api.github.com/repos/atmos/slash-heroku/tarball/8115792777a8d60fcf1c5e181ce3c3bc34e5eb1b")
        .with(headers: default_github_headers)
        .to_return(status: 200, body: nil, headers: tarball_headers)

      response = fixture_data("api.heroku.com/apps/slash-heroku-production/builds")
      stub_request(:post, "https://api.heroku.com/apps/slash-heroku-production/builds")
        .with(body: "{\"source_blob\":{\"url\":\"https://codeload.github.com/atmos/slash-heroku/legacy.tar.gz/8115792777a8d60fcf1c5e181ce3c3bc34e5eb1b\",\"version\":\"8115792777a8d60fcf1c5e181ce3c3bc34e5eb1b\",\"version_description\":\"atmos/slash-heroku:8115792777a8d60fcf1c5e181ce3c3bc34e5eb1b\"}}")
        .to_return(status: 200, body: response, headers: {})

      response = fixture_data("api.github.com/repos/atmos/slash-heroku/deployments/22062424/statuses/pending-1")
      stub_request(:post, "https://api.github.com/repos/atmos/slash-heroku/deployments/22062424/statuses")
        .with(headers: default_github_headers)
        .to_return(status: 200, body: response, headers: {})

      pipeline   = Escobar::Heroku::Pipeline.new(client, id, name)
      deployment = pipeline.create_deployment("master", "production")

      expect(deployment.id).to eql("01234567-89ab-cdef-0123-456789abcdef")
      expect(deployment.app_id).to eql("b0deddbf-cf56-48e4-8c3a-3ea143be2333")
      expect(deployment.github_url).to eql("https://api.github.com/repos/atmos/slash-heroku/deployments/22062424")
      expect(deployment.dashboard_build_output_url).to eql(
        "https://dashboard.heroku.com/apps/slash-heroku-production/activity/builds/01234567-89ab-cdef-0123-456789abcdef"
      )
      expect(deployment.sha).to eql("8115792777a8d60fcf1c5e181ce3c3bc34e5eb1b")
      expect(deployment.repository).to eql("atmos/slash-heroku")
      expect(deployment.pipeline_name).to eql("slash-heroku")
      expect(deployment.to_job_json).to eql(
        sha: "8115792777a8d60fcf1c5e181ce3c3bc34e5eb1b",
        pipeline_name: "slash-heroku",
        repo: "atmos/slash-heroku",
        app_id: "b0deddbf-cf56-48e4-8c3a-3ea143be2333",
        app_name: "slash-heroku-production",
        build_id: "01234567-89ab-cdef-0123-456789abcdef",
        command_id: nil,
        target_url: deployment.dashboard_build_output_url,
        deployment_url: deployment.github_url
      )

      app_path = "/apps/b0deddbf-cf56-48e4-8c3a-3ea143be2333"
      stub_heroku_response(
        "#{app_path}/builds/01234567-89ab-cdef-0123-456789abcdef"
      )
      build = pipeline.reap_build(
        deployment.app_id, deployment.id
      )
      expect(build.status).to eql("succeeded")
      expect(build).to be_releasing

      stub_heroku_response(
        "#{app_path}/releases/23fe935d-88c8-4fd0-b035-10d44f3d9059"
      )
      release = pipeline.reap_release(
        build.app_id, build.id, build.release_id
      )
      expect(release.status).to eql("succeeded")
    end

    it "create_deployment errors on two factor requirements for apps" do
      pipeline_path = "/pipelines/#{id}"
      stub_heroku_response("/apps/b0deddbf-cf56-48e4-8c3a-3ea143be2333")
      stub_heroku_response("/apps/760bc95e-8780-4c76-a688-3a4af92a3eee")
      stub_heroku_response(pipeline_path)
      stub_heroku_response("#{pipeline_path}/pipeline-couplings")
      stub_kolkrabbi_response("#{pipeline_path}/repository")

      response = fixture_data("api.github.com/repos/atmos/slash-heroku/index")
      stub_request(:get, "https://api.github.com/repos/atmos/slash-heroku")
        .with(headers: default_github_headers)
        .to_return(status: 200, body: response, headers: {})

      response = fixture_data("api.github.com/repos/atmos/slash-heroku/branches/master")
      stub_request(:get, "https://api.github.com/repos/atmos/slash-heroku/branches/master")
        .with(headers: default_github_headers)
        .to_return(status: 200, body: response, headers: {})

      response = fixture_data("api.github.com/repos/atmos/slash-heroku/deployments")
      stub_request(:post, "https://api.github.com/repos/atmos/slash-heroku/deployments")
        .with(headers: default_github_headers)
        .to_return(status: 200, body: response, headers: {})

      response = fixture_data("api.heroku.com/failed-2fa")
      stub_request(:get, "https://api.heroku.com/apps/b0deddbf-cf56-48e4-8c3a-3ea143be2333/config-vars")
        .to_return(status: 403, body: response, headers: {})

      pipeline = Escobar::Heroku::Pipeline.new(client, id, name)
      expect { pipeline.create_deployment("master", "production") }
        .to raise_error(
          Escobar::Heroku::BuildRequest::Error,
          "Application requires second factor: slash-heroku-production"
        )
    end
    # rubocop:enable Metrics/LineLength
  end
end
