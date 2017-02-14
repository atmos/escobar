module Escobar
  module Heroku
    # Class representing a heroku application's environment variables
    class ConfigVars
      attr_reader :client, :app_id
      def initialize(client, app_id)
        @app_id = app_id
        @client = client
      end

      # Retrieve an environmental variable by name
      def [](key)
        values[key]
      end

      def values
        @info ||= info
      end

      def info
        if info_json["id"] == "two_factor" &&
           info_json["message"].match(/second authentication factor/)
          {}
        else
          info_json
        end
      end

      def info_json
        @info_json ||= client.heroku.get("/apps/#{app_id}/config-vars")
      end
    end
  end
end
