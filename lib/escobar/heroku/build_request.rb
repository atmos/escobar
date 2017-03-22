module Escobar
  module Heroku
    # Class representing a heroku build request
    class BuildRequest
      # Class representing some failure when requesting a build
      class Error < StandardError
        attr_accessor :build_request

        def self.new_from_build_request(build_request, message)
          error = new(message)
          error.build_request = build_request
          error
        end

        def dashboard_url
          "https://dashboard.heroku.com/apps/#{build_request.app.name}"
        end
      end

      # Class representing a rejected GitHub deployment
      class MissingContextsError < Error
        attr_accessor :missing_contexts
        def self.new_from_build_request_and_error(build_request, error)
          err = new(error.default_message)
          err.build_request = build_request
          err.missing_contexts = error.missing_contexts
          err
        end
      end

      class RequiresTwoFactorError < Error
      end

      attr_reader :app_id, :github_deployment_url, :pipeline, :sha

      attr_accessor :environment, :ref, :forced, :custom_payload

      def initialize(pipeline, app_id)
        @app_id   = app_id
        @pipeline = pipeline
      end

      def app
        @app ||= Escobar::Heroku::App.new(pipeline.client, app_id)
      end

      def error_for(message)
        Error.new_from_build_request(self, message)
      end

      def cache_key
        app.cache_key
      end

      def create(task, environment, ref, forced, custom_payload)
        raise_2fa_error if app.locked?

        @environment = environment
        @ref = ref
        @forced = forced
        @custom_payload = custom_payload

        create_in_api(task)
      end

      def raise_2fa_error
        message = "Application requires second factor: #{app.name}"
        raise RequiresTwoFactorError.new_from_build_request(self, message)
      end

      def create_in_api(task)
        create_github_deployment(task)

        build = create_heroku_build
        if build["id"] =~ Escobar::UUID_REGEX
          process_heroku_build(build)
        else
          raise error_for(
            "Unable to create heroku build for #{app.name}: #{build['message']}"
          )
        end
      end

      def process_heroku_build(build)
        heroku_build = Escobar::Heroku::Build.new(
          pipeline.client, app_id, build["id"]
        )

        create_github_pending_deployment_status(heroku_build)

        heroku_build.github_url = github_deployment_url
        heroku_build.pipeline_name = pipeline.name
        heroku_build.sha = sha

        heroku_build
      end

      def create_heroku_build
        body = {
          source_blob: {
            url: github_client.archive_link(sha),
            version: sha,
            version_description: "#{pipeline.github_repository}:#{sha}"
          }
        }
        app.client.heroku.post("/apps/#{app.name}/builds", body)
      end

      def handle_github_deployment_response(response)
        unless response["sha"]
          handle_github_deployment_error(response)
        end

        @sha = response["sha"]
        @github_deployment_url = response["url"]
        response
      end

      def handle_github_deployment_error(response)
        error = Escobar::GitHub::DeploymentError.new(
          pipeline.github_repository, response, required_commit_contexts
        )
        raise error_for(error.default_message) unless error.missing_contexts?
        raise MissingContextsError.new_from_build_request_and_error(self, error)
      end

      def create_github_deployment(task)
        options = {
          ref: ref,
          task: task,
          auto_merge: !forced,
          payload: custom_payload.merge(custom_deployment_payload),
          environment: environment,
          required_contexts: required_commit_contexts
        }
        response = github_client.create_deployment(options)
        handle_github_deployment_response(response)
      end

      def create_deployment_status(url, payload)
        github_client.create_deployment_status(url, payload)
      end

      def create_github_pending_deployment_status(heroku_build)
        create_github_deployment_status(
          github_deployment_url,
          heroku_build.dashboard_build_output_url,
          "pending",
          "Build running.."
        )
      end

      def create_github_deployment_status(url, target_url, state, description)
        payload = {
          state: state,
          target_url: target_url,
          description: description
        }
        create_deployment_status(url, payload)
      end

      def custom_deployment_payload
        { name: app.name, pipeline: pipeline.to_hash, provider: "slash-heroku" }
      end

      def required_commit_contexts
        return [] if forced || environment != "production"
        github_client.required_contexts.map do |context|
          if context == "continuous-integration/travis-ci"
            context = "continuous-integration/travis-ci/push"
          end
          context
        end
      end

      def github_client
        @github_client ||= Escobar::GitHub::Client.new(
          app.client.github_token,
          pipeline.github_repository
        )
      end
    end
  end
end
