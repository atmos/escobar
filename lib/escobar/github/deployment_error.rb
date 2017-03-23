module Escobar
  module GitHub
    # Consolidate GitHub deployment api failures for easier messaging
    class DeploymentError < StandardError
      attr_accessor :repo, :response, :required_commit_contexts

      def initialize(repo, response, required_commit_contexts)
        @repo = repo
        @response = response
        @required_commit_contexts = required_commit_contexts
      end

      def missing_contexts?
        missing_contexts.any?
      end

      def succeeded_required_contexts
        error = response.fetch("errors", [])[0]
        return [] unless error && error["field"] == "required_contexts"
        contexts = error["contexts"]
        contexts.each_with_object([]) do |context, succeeded|
          success = (context["state"] == "success")
          required = required_commit_contexts.include?(context["context"])
          succeeded << context["context"] if required && success
        end
      end

      def missing_contexts
        required_commit_contexts - succeeded_required_contexts
      end

      def response_message
        response["message"]
      end

      def default_message
        "Unable to create GitHub deployments for #{repo}: #{response_message}"
      end
    end
  end
end
