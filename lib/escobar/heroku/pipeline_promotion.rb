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
        sleep 2 # releases aren't present immediately
        results = Escobar::Heroku::PipelinePromotionTargets.new(
          self, response
        )
        results.releases
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
