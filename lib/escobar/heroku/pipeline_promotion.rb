module Escobar
  module Heroku
    # Class reperesenting a Heroku Pipeline Promotion
    class PipelinePromotion
      attr_reader :client, :id, :name, :pipline, :source, :targets
      def initialize(pipeline, source, targets)
        @id       = pipeline.id
        @client   = pipeline.client
        @pipeline = pipeline
        @source   = source
        @targets  = targets
      end

      def promotion_path
        "/pipeline-promotions"
      end

      def create
        response = client.heroku.post(promotion_path, body)
        results = Escobar::Heroku::PipelinePromotionTargets.new(
          self, response["id"]
        )
        results.releases
      end

      def body
        {
          pipline: { id: id },
          source: { app: { id: source.id } },
          targets: targets.map(&:id)
        }
      end
    end
  end
end
