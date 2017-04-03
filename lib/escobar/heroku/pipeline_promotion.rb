module Escobar
  module Heroku
    # Class reperesenting a Heroku Pipeline Promotion
    class PipelinePromotion
      attr_reader :client, :id, :name, :pipeline,
                  :source, :targets, :second_factor
      def initialize(client, pipeline, source, targets, second_factor)
        @id = pipeline.id
        @client = client
        @source = source
        @targets = targets
        @pipeline = pipeline
        @second_factor = second_factor
      end

      def promotion_path
        "/pipeline-promotions"
      end

      def create
        response = client.heroku.post(promotion_path, body, second_factor)
        case response["id"]
        when Escobar::UUID_REGEX
          sleep 2 # releases aren't present immediately
          results = Escobar::Heroku::PipelinePromotionTargets.new(
            self, response
          )
          results.releases
        when "two_factor"
          raise_2fa_error
        else
          raise ArgumentError, response.to_json
        end
      end

      class RequiresTwoFactorError < ArgumentError
      end

      class MissingContextsError < \
        Escobar::Heroku::BuildRequest::MissingContextsError
      end

      def raise_2fa_error
        message = "Application requires second factor: #{pipeline.name}"
        raise RequiresTwoFactorError, message
      end

      def body
        {
          pipeline: { id: id },
          source: { app: { id: source.id } },
          targets: targets.map { |t| { app: { id: t.id } } }
        }
      end
    end
  end
end
