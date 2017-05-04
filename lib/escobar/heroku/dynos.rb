module Escobar
  module Heroku
    # Class representing an app's dyno state
    class Dynos
      ONE_OFF_TYPES = %w{run scheduler}.freeze

      attr_reader :app_id, :client

      attr_accessor :command_id
      attr_accessor :github_url
      attr_accessor :pipeline_name

      def initialize(client, app_id)
        @app_id = app_id
        @client = client
      end

      def info
        @info ||= client.heroku.get("/apps/#{app_id}/dynos")
      end

      def non_one_off
        info.reject { |dyno| ONE_OFF_TYPES.include?(dyno["type"]) }
      end

      def running?(release_id)
        non_one_off.all? do |dyno|
          dyno["release"]["id"] == release_id && dyno["state"] == "up"
        end
      end

      def running_at_least?(version)
        non_one_off.all? do |dyno|
          dyno["release"]["version"] >= version && dyno["state"] == "up"
        end
      end

      def newer_than?(epoch)
        non_one_off.all? do |dyno|
          epoch < Time.parse(dyno["created_at"]).utc
        end
      end
    end
  end
end
