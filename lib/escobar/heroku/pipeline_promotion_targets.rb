module Escobar
  module Heroku
    # Class reperesenting a Heroku Pipeline Promotion Targets
    class PipelinePromotionTargets
      attr_reader :client, :id, :name, :pipline
      def initialize(pipeline, promotion)
        @id       = promotion["id"]
        @name     = pipeline.name
        @client   = pipeline.client
        @pipeline = pipeline
      end

      def release_id
        promotion["source"]["release"]["id"]
      end

      def app_id
        promotion["source"]["app"]["id"]
      end

      def release
        @release ||= Escobar::Heroku::Release.new(
          client, app_id, nil, release_id
        )
      end

      def ref
        @ref ||= release.ref
      end

      def targets_path
        "/pipeline-promotions/#{id}/promotion-targets"
      end

      def info
        @info ||= client.heroku.get(promotion_path)
      end

      def releases
        info.map do |target|
          Escobar::Heroku::Release.new(
            client, target["app"]["id"], nil, target["release"]["id"]
          )
        end
      end
    end
  end
end
