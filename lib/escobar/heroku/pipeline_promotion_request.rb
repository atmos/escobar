module Escobar
  module Heroku
    # Class reperesenting a request for Pipeline Promotion
    class PipelinePromotionRequest
      attr_reader :client, :id, :name, :pipeline, :source, :targets
      attr_reader :github_deployment_url, :sha

      attr_accessor :environment, :ref, :forced, :custom_payload

      def initialize(pipeline, source, targets)
        @id       = pipeline.id
        @client   = pipeline.client
        @pipeline = pipeline
        @source   = source
        @targets  = targets
      end

      def create(environment, forced, custom_payload)
        raise ArgumentError, "No target applications" if @target.empty?
        @environment = environment
        @forced = forced
        @custom_payload = custom_payload

        create_in_api
      end

      def create_in_api
        create_github_deployment(environment, custom_payload)
        promotion = Escobar::Heroku::PipelinePromotion.new(
          self, source, targets
        )
        releases = promotion.create
        handle_github_deployment_statuses_for(releases)
        releases
      end

      def handle_github_deployment_statuses_for(releases)
        releases.each do |release|
          custom_payload_for_app = custom_payload.merge(app_id: release.app.id)
          unless github_deployment_url
            create_github_deployment(environment, custom_payload_for_app)
          end
          release.github_url = github_deployment_url
          create_github_deployment_status(
            github_deployment_url,
            release.dashboard_build_output_url,
            "pending",
            "Promotion releasing.."
          )
          @github_deployment_url = nil
        end
      end

      private

      def create_github_deployment_status(url, target_url, state, description)
        payload = {
          state: state,
          target_url: target_url,
          description: description
        }
        create_deployment_status(url, payload)
      end

      def create_github_deployment(environment, custom_payload)
        options = {
          ref: ref,
          task: "promote",
          auto_merge: false,
          payload: custom_payload.merge(custom_deployment_payload),
          environment: environment,
          required_contexts: required_commit_contexts
        }
        response = github_client.create_deployment(options)
        handle_github_deployment_response(response)
      end

      def custom_deployment_payload
        {
          source: source.id,
          pipeline: pipeline.to_hash,
          provider: "slash-heroku"
        }
      end

      def github_client
        @github_client ||= Escobar::GitHub::Client.new(
          client.github_token,
          pipeline.github_repository
        )
      end

      def required_commit_contexts
        pipeline.required_commit_contexts(false)
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
    end
  end
end
