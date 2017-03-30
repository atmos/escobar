module Escobar
  module Heroku
    # Class representing a heroku slug
    class Slug
      attr_reader :app_id, :app_name, :client, :id

      attr_accessor :sha

      def initialize(client, app_id, id)
        @id       = id
        @app_id   = app_id
        @client   = client
      end

      def info
        @info ||= client.heroku.get("/apps/#{app_id}/slugs/#{id}")
      end

      def ref
        info["commit"]
      end
    end
  end
end
