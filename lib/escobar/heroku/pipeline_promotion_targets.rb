module Escobar
  module Heroku
    # Class reperesenting a Heroku Pipeline Promotion Targets
    class PipelinePromotionTargets
      attr_reader :client, :id, :name, :pipeline, :promotion

      def initialize(pipeline, promotion)
        @id       = promotion["id"]
        @name     = pipeline.name
        @client   = pipeline.client
        @pipeline = pipeline
        @retries  = 30
      end

      def release_id
        promotion["source"]["release"]["id"]
      end

      def app_id
        promotion["source"]["app"]["id"]
      end

      def source_release
        @release ||= Escobar::Heroku::Release.new(
          client, app_id, nil, release_id
        )
      end

      def ref
        @ref ||= source_release.ref
      end

      def targets_path
        "/pipeline-promotions/#{id}/promotion-targets"
      end

      def info
        @info ||= client.heroku.get(targets_path)
      end

      def releases
        info.map do |target|
          target_app_id     = target["app"]["id"]
          target_release_id = target["release"]["id"]
          Escobar::Heroku::Release.new(
            client, target_app_id, nil, target_release_id
          )
        end
      rescue NoMethodError
        raise(ArgumentError, info.to_json) unless retry?
        sleep 0.5
        @retries -= 1
        @info = nil
        retry
      end

      def retry?
        @retries.positive?
      end
    end
  end
end
