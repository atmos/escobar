module Escobar
  module Heroku
    # Class representing a heroku release
    class Release
      attr_reader :app_id, :app_name, :build_id, :client, :id

      attr_accessor :command_id
      attr_accessor :github_url
      attr_accessor :pipeline_name
      attr_accessor :sha

      def initialize(client, app_id, build_id, id)
        @id       = id
        @app_id   = app_id
        @build_id = build_id
        @client   = client
      end

      def info
        @info ||= client.heroku.get("/apps/#{app_id}/releases/#{id}")
      end

      def app
        @app ||= Escobar::Heroku::App.new(client, app_id)
      end

      def build
        @build ||= Escobar::Heroku::Build.new(client, app.id, build_id)
      end

      def slug
        @slug ||= Escobar::Heroku::Slug.new(client, app.id, info["slug"]["id"])
      end

      def ref
        slug && slug.ref
      end

      def dashboard_release_output_url
        "https://dashboard.heroku.com/apps/#{app.name}/activity/releases/#{id}"
      end

      def repository
        github_url && github_url.match(repository_regex)[1]
      end

      def repository_regex
        %r{https:\/\/api\.github\.com\/repos\/([-_\.0-9a-z]+\/[-_\.0-9a-z]+)}
      end

      def status
        info["status"]
      end

      def to_job_json
        {
          sha: sha,
          name: pipeline_name,
          repo: repository,
          app_id: app_id,
          app_name: app.name,
          build_id: build_id,
          release_id: id,
          command_id: command_id,
          target_url: dashboard_release_output_url,
          deployment_url: github_url
        }
      end
    end
  end
end
