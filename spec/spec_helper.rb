$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "base64"
require "escobar"
require "fileutils"
require "uuid"
require "webmock/rspec"
require "byebug"

tmp_directory = File.expand_path("../../tmp", __FILE__)
FileUtils.mkdir_p tmp_directory
ENV["NETRC"] = tmp_directory
ENV["KOLKRABBI_HOSTNAME"] = "kolkrabbit.com"

RSpec.configure do |config|
  config.include(WebMock::API)

  config.before(:all) do
    File.open("#{ENV['NETRC']}/.netrc", File::RDWR | File::CREAT, 0o600) do |fp|
      netrc_file_contents.each do |uri, entry|
        fp.write "machine #{uri}\n  login #{entry['login']}\n" \
                   "  password #{entry['password']}\n"
      end
    end
  end

  config.before do
    WebMock.reset!
    WebMock.disable_net_connect!
    ENV["NETRC"] = tmp_directory
  end

  def uuid
    @uuid ||= UUID.new
  end

  def netrc_file_contents
    {
      "api.heroku.com" => {
        "login" => "atmos@atmos.org",
        "password" => uuid.generate
      },
      "git.heroku.com" => {
        "login" => "atmos@atmos.org",
        "password" => uuid.generate
      },
      "api.github.com" => {
        "login" => "atmos",
        "password" => Digest::SHA1.hexdigest(Time.now.to_f.to_s)
      }
    }
  end

  def fixture_path
    "#{File.expand_path('../..', __FILE__)}/spec/fixtures"
  end

  def fixture_data(name)
    path = File.join(fixture_path, "#{name}.json")
    File.read(path)
  end

  def decoded_fixture_data(name)
    JSON.parse(fixture_data(name))
  end

  def default_github_headers
    {
      "Accept"          => "application/vnd.github.loki-preview+json",
      "Authorization"   => "token #{Escobar.github_api_token}",
      "Content-Type"    => "application/json",
      "User-Agent"      => "Faraday v0.9.2"
    }
  end

  def default_heroku_headers(version = 3)
    {
      "Accept"          => "application/vnd.heroku+json; version=#{version}",
      "Accept-Encoding" => "",
      "Authorization"   => "Bearer #{Escobar.heroku_api_token}",
      "Content-Type"    => "application/json",
      "User-Agent"      => "Faraday v0.9.2"
    }
  end

  def default_kolkrabbi_headers
    {
      "Accept"          => "*/*",
      "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
      "Authorization"   => "Bearer #{Escobar.heroku_api_token}",
      "Content-Type"    => "application/json",
      "User-Agent"      => "Faraday v0.9.2"
    }
  end

  def stub_heroku_response(path)
    stub_request(:get, "https://api.heroku.com#{path}")
      .with(headers: default_heroku_headers)
      .to_return(status: 200, body: fixture_data("api.heroku.com#{path}"))
  end

  def stub_kolkrabbi_response(path)
    stub_request(:get, "https://kolkrabbit.com#{path}")
      .with(headers: default_kolkrabbi_headers)
      .to_return(status: 200, body: fixture_data("kolkrabbi#{path}"))
  end
end
