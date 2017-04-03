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

      def current_release_ref
        releases.first.ref
      end

      def dynos
        @dynos ||= Escobar::Heroku::Dynos.new(client, id)
      end

      def config_vars
        @config_vars ||= Escobar::Heroku::ConfigVars.new(client, id)
      end

      def log_drains
        @log_drains ||= client.heroku.get("/apps/#{id}/log-drains")
      end

      def dashboard_url
        "https://dashboard.heroku.com/apps/#{name}"
      end

      def cache_key
        "escobar-app-#{id}"
      end

      # Accepts either google authenticator or yubikey second_factor formatting
      def preauth(second_factor)
        client.heroku.put("/apps/#{id}/pre-authorizations", second_factor).none?
      end

      def locked?
        response = client.heroku.get("/apps/#{id}/config-vars")
        response["id"] == "two_factor"
      rescue Escobar::Client::HTTPError => e
        response = JSON.parse(e.response.body)
        response["id"] == "two_factor"
      end

      def direct_to_drain?
        !log_drains.is_a?(Array)
      end

      def drain_token
        @drain_token ||= drain && drain["token"]
      end

      def log_url
        @log_url ||= "#{dashboard_url}/logs"
      end

      def build_request_for(pipeline)
        Escobar::Heroku::BuildRequest.new(pipeline, id)
      end

      def drain
        @drain ||= log_drains.find do |drain|
          drain["url"].match(heroku_drain_url_pattern)
        end
      end

      def heroku_drain_url_pattern
        %r{forward\.log\.herokai\.com:9999|logs\.herokai\.com\/logs}
      end
    end
  end
end
