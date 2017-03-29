module Escobar
  module Heroku
    # Class reperesenting a Heroku Pipeline Promotion Targets
    class PipelinePromotionTargets
      attr_reader :client, :id, :name, :pipline
      def initialize(pipeline, id)
        @id       = id
        @name     = pipeline.name
        @client   = pipeline.client
        @pipeline = pipeline
      end

      def targets_path
        "/pipeline-promotions/#{id}/promotion-targets"
      end

      def info
        @info ||= client.heroku.get(promotion_path)
      end

      def releases
        info.map do |target|
          Escobar::Heroku::Release.new(client, target["app"]["id"],
                                       nil, target["release"]["id"])
        end
      end
    end
  end
end
