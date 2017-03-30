module Escobar
  module Heroku
    # Class reperesenting a request for Pipeline Promotion
    class PipelinePromotionRequest
      attr_reader :client, :id, :name, :pipline, :source, :targets
      def initialize(pipeline, source, targets)
        @id       = pipeline.id
        @client   = pipeline.client
        @pipeline = pipeline
        @source   = source
        @targets  = targets
      end

      private

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
    end
  end
end
