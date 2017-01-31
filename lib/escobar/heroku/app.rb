module Escobar
  module Heroku
    # Class representing a heroku application
    class App
      attr_reader :client, :id
      def initialize(client, id)
        @id     = id
        @client = client
      end

      def name
        info["name"]
      end

      def info
        @info ||= client.heroku.get("/apps/#{id}")
      end

      def releases_json
        @releases_json ||= client.heroku.get_range(
          "/apps/#{id}/releases", "version; order=desc,max=25;"
        )
      end

      def releases
        @releases ||= releases_json.map do |release|
          Escobar::Heroku::Release.new(client, id, nil, release["id"])
        end
      end

      def dashboard_url
        "https://dashboard.heroku.com/apps/#{name}"
      end

      def cache_key
        "escobar-app-#{id}"
      end

      # Accepts either google authenticator or yubikey second_factor formatting
      def preauth(second_factor)
        !client.heroku.put("/apps/#{id}/pre-authorizations", second_factor).any?
      end

      def locked?
        response = client.heroku.get("/apps/#{id}/config-vars")
        response["id"] == "two_factor"
      end

      def build_request_for(pipeline)
        Escobar::Heroku::BuildRequest.new(pipeline, id)
      end
    end
  end
end
