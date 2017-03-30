module Escobar
  module Heroku
    # Class reperesenting a Heroku Pipeline Promotion
    class PipelinePromotion
      attr_reader :client, :id, :name, :pipeline, :source, :targets
      def initialize(client, pipeline, source, targets)
        @id       = pipeline.id
        @client   = client
        @pipeline = pipeline
        @source   = source
        @targets  = targets
      end

      def promotion_path
        "/pipeline-promotions"
      end

      def create
        response = client.heroku.post(promotion_path, body)
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
