module Escobar
  module Heroku
    # Class representing a heroku build
    class Build
      attr_reader :app_id, :client, :id

      attr_accessor :command_id
      attr_accessor :github_url
      attr_accessor :pipeline_name
      attr_accessor :sha

      def initialize(client, app_id, id)
        @id            = id
        @app_id        = app_id
        @client        = client
      end

      def info
        @info ||= client.heroku.get("/apps/#{app_id}/builds/#{id}")
      end

      def status
        info["status"]
      end

      def releasing?
        status == "succeeded" && !release_id.nil?
      end

      def release_id
        info["release"]["id"]
      end

      def app
        @app ||= Escobar::Heroku::App.new(client, app_id)
      end

      def dashboard_build_output_url
        "https://dashboard.heroku.com/apps/#{app.name}/activity/builds/#{id}"
      end

      def repository
        github_url && github_url.match(Escobar::GitHub::REPOSITORY_REGEX)[1]
      end

      def to_job_json
        {
          sha: sha,
          pipeline_name: pipeline_name,
          repo: repository,
          app_id: app_id,
          app_name: app.name,
          build_id: id,
          command_id: command_id,
          target_url: dashboard_build_output_url,
          deployment_url: github_url
        }
      end
    end
  end
end
