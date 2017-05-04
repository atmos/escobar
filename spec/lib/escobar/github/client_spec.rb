require "spec_helper"

describe Escobar::GitHub::Client do
  let(:escobar) { Escobar::Client.from_environment }
  let(:hubot) do
    Escobar::GitHub::Client.new(escobar.github_token, "atmos/hubot")
  end
  let(:slash_heroku) do
    Escobar::GitHub::Client.new(escobar.github_token, "atmos/slash-heroku")
  end

  before do
    WebMock.disable_net_connect!
  end

  # rubocop:disable Metrics/LineLength
  describe "#archive_link" do
    it "gets an archive link for a repository" do
      token = Base64.encode64(Time.now.utc.to_s)
      url = "https://codeload.github.com/atmos/hubot/legacy.tar.gz/master?token=#{token}"
      stub_request(:head, "https://api.github.com/repos/atmos/hubot/tarball/master")
        .with(headers: default_github_headers)
        .to_return(status: 200, body: "", headers: { "Location" => url })

      expect(url).to eql(hubot.archive_link("master"))
    end
  end

  describe "#default_branch" do
    it "returns an empty array when none are found" do
      response = fixture_data("api.github.com/repos/atmos/hubot/index")
      stub_request(:get, "https://api.github.com/repos/atmos/hubot")
        .with(headers: default_github_headers)
        .to_return(status: 200, body: response, headers: {})

      expect(hubot.default_branch).to eql("production")
    end

    it "returns an array of strings when they are found" do
      response = fixture_data("api.github.com/repos/atmos/slash-heroku/index")
      stub_request(:get, "https://api.github.com/repos/atmos/slash-heroku")
        .with(headers: default_github_headers)
        .to_return(status: 200, body: response, headers: {})

      expect(slash_heroku.default_branch).to eql("master")
    end

    it "raises a RepoNotFound error if the repo can't be found with the token" do
      response = { message: "Not Found",
                   documentation_url: "https://developer.github.com/v3" }.to_json

      stub_request(:get, "https://api.github.com/repos/atmos/slash-heroku")
        .with(headers: default_github_headers)
        .to_return(status: 404, body: response, headers: {})

      expect do
        slash_heroku.default_branch
      end.to raise_error(Escobar::GitHub::RepoNotFound)
    end

    it "raises a Unauthorized error if we get a 401" do
      stub_request(:get, "https://api.github.com/repos/atmos/slash-heroku")
        .with(headers: default_github_headers)
        .to_return(status: 401, body: {}.to_json, headers: {})

      expect do
        slash_heroku.default_branch
      end.to raise_error(Escobar::Client::Error::Unauthorized)
    end
  end

  describe "#required_contexts" do
    it "returns an empty array when none are found" do
      response = fixture_data("api.github.com/repos/atmos/hubot/index")
      stub_request(:get, "https://api.github.com/repos/atmos/hubot")
        .with(headers: default_github_headers)
        .to_return(status: 200, body: response, headers: {})

      response = fixture_data("api.github.com/repos/atmos/hubot/branches/production")
      stub_request(:get, "https://api.github.com/repos/atmos/hubot/branches/production")
        .with(headers: default_github_headers)
        .to_return(status: 200, body: response, headers: {})

      expect(hubot.required_contexts).to be_empty
    end

    it "returns an array of strings when they are found" do
      response = fixture_data("api.github.com/repos/atmos/slash-heroku/index")
      stub_request(:get, "https://api.github.com/repos/atmos/slash-heroku")
        .with(headers: default_github_headers)
        .to_return(status: 200, body: response, headers: {})
      response = fixture_data("api.github.com/repos/atmos/slash-heroku/branches/master")
      stub_request(:get, "https://api.github.com/repos/atmos/slash-heroku/branches/master")
        .with(headers: default_github_headers)
        .to_return(status: 200, body: response, headers: {})

      expect(slash_heroku.required_contexts).to eql(["continuous-integration/travis-ci/push"])
    end

    it "raises a RepoNotFound error if the repo can't be found with the token" do
      response = { message: "Not Found",
                   documentation_url: "https://developer.github.com/v3" }.to_json

      stub_request(:get, "https://api.github.com/repos/atmos/slash-heroku")
        .with(headers: default_github_headers)
        .to_return(status: 404, body: response, headers: {})

      expect do
        slash_heroku.required_contexts
      end.to raise_error(Escobar::GitHub::RepoNotFound)
    end
  end

  describe "#create_deployment" do
    it "creates a deployment given a set of information" do
      response = fixture_data("api.github.com/repos/atmos/hubot/deployments/success")
      stub_request(:post, "https://api.github.com/repos/atmos/hubot/deployments")
        .with(headers: default_github_headers)
        .to_return(status: 200, body: response, headers: {})

      options = {
        ref: "mybranch",
        payload: {},
        environment: "production"
      }

      deployment = hubot.create_deployment(options)
      expect(deployment["sha"]).to eql("26439af517132e32eb7cf329cd1ca4d8bad973a0")
      expect(deployment["url"])
        .to eql("https://api.github.com/repos/atmos/hubot/deployments/4303989")
    end
  end
  # rubocop:enable Metrics/LineLength

  describe "#deployments" do
    it "returns an array of deployments" do
      deploy_url = "https://api.github.com/repos/atmos/slash-heroku/deployments"
      response = fixture_data(
        "api.github.com/repos/atmos/slash-heroku/deployments"
      )
      stub_request(:get, deploy_url)
        .with(headers: default_github_headers)
        .to_return(status: 200, body: response, headers: {})

      expect(slash_heroku.deployments).to_not be_empty
    end
  end
end
