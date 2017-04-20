module Escobar
  module Heroku
    # Class reperesenting a request for Pipeline Promotion
    class PipelinePromotionRequest
      attr_reader :client, :id, :name, :pipeline, :source, :targets
      attr_reader :github_deployment_url, :sha

      attr_accessor :environment, :forced, :custom_payload, :second_factor

      def initialize(client, pipeline, source, targets, second_factor)
        @id = pipeline.id
        @client = client
        @pipeline = pipeline
        @source = source
        @targets = targets || []
        @second_factor = second_factor
      end

      def create(environment, forced, custom_payload)
        raise ArgumentError, "No target applications" if targets.empty?
        @environment = environment
        @forced = forced
        @custom_payload = custom_payload

        fill_promotion_target_urls
        create_in_api
      end

      def create_in_api
        promotion = Escobar::Heroku::PipelinePromotion.new(
          client, pipeline, source, targets, second_factor
        )

        releases = promotion.create
        handle_github_deployment_statuses_for(releases)
        releases
      rescue PipelinePromotion::RequiresTwoFactorError
        handle_2fa_failure
        raise
      end

      def handle_2fa_failure
        target_urls.values.each do |target_url|
          create_github_deployment_status(
            target_url,
            nil,
            "error",
            "Missing second factor"
          )
        end
      end

      def handle_github_deployment_statuses_for(releases)
        releases.each do |release|
          release.sha = release.ref
          release.github_url = target_urls[release.app.id]
          release.pipeline_name = pipeline.name

          create_github_deployment_status(
            release.github_url,
            release.dashboard_release_output_url,
            "pending",
            "Promotion releasing.."
          )
        end
      end

      private

      def target_urls
        @target_urls ||= {}
      end

      def fill_promotion_target_urls
        targets.each do |target|
          custom_payload_for_app = custom_payload.merge(
            app_id: target.id, name: target.name
          )
          create_github_deployment(environment, custom_payload_for_app)
          target_urls[target.id] = github_deployment_url
        end
      end

      def create_github_deployment_status(url, target_url, state, description)
        payload = {
          state: state,
          target_url: target_url,
          description: description
        }
        create_deployment_status(url, payload)
      end

      def create_deployment_status(url, payload)
        github_client.create_deployment_status(url, payload)
      end

      def create_github_deployment(environment, custom_payload)
        options = {
          ref: source.current_release_ref,
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
        pipeline.required_commit_contexts(forced)
      end

      def handle_github_deployment_response(response)
        unless response["sha"]
          handle_github_deployment_error(response)
        end

        @sha = response["sha"]
        @github_deployment_url = response["url"]
        response
      end

      class MissingContextsError < \
        Escobar::Heroku::PipelinePromotion::MissingContextsError
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
