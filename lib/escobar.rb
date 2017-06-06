require "netrc"
require "faraday"
require "json"
require "escobar/version"

# Top-level module for Escobar code
module Escobar
  UUID_REGEX = /[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/

  def self.netrc
    @netrc ||= begin
                 if env_netrc
                   env_netrc
                 else
                   home_netrc
                 end
               end
  end

  def self.env_netrc
    @env_netrc ||= begin
                     if ENV["NETRC"]
                       Netrc.read("#{ENV['NETRC']}/.netrc")
                     end
                   rescue Errno::ENOTDIR
                     nil
                   end
  end

  def self.home_netrc
    @home_netrc ||= begin
                      if ENV["HOME"]
                        Netrc.read("#{ENV['HOME']}/.netrc")
                      end
                    rescue Errno::ENOTDIR
                      nil
                    end
  end

  def self.heroku_api_token
    netrc["api.heroku.com"]["password"]
  end

  def self.github_api_token
    netrc["api.github.com"]["password"]
  end

  def self.zipkin_enabled?
    !ENV["ZIPKIN_SERVICE_NAME"].nil? && !ENV["ZIPKIN_API_HOST"].nil?
  end

  def self.http_open_timeout
    3
  end

  def self.http_timeout
    6
  end
end

require_relative "./escobar/client"
require_relative "./escobar/github/response/raise_error"
require_relative "./escobar/github/client"
require_relative "./escobar/github/deployment_error"
require_relative "./escobar/heroku/app"
require_relative "./escobar/heroku/build"
require_relative "./escobar/heroku/build_request"
require_relative "./escobar/heroku/client"
require_relative "./escobar/heroku/dynos"
require_relative "./escobar/heroku/release"
require_relative "./escobar/heroku/coupling"
require_relative "./escobar/heroku/pipeline"
require_relative "./escobar/heroku/config_vars"
require_relative "./escobar/heroku/slug"
require_relative "./escobar/heroku/pipeline_promotion"
require_relative "./escobar/heroku/pipeline_promotion_request"
require_relative "./escobar/heroku/pipeline_promotion_targets"
require_relative "./escobar/heroku/user"
