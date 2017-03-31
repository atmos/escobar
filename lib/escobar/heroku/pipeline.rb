module Escobar
  module Heroku
    # Class reperesenting a Heroku Pipeline
    class Pipeline
      attr_reader :client, :id, :name
      def initialize(client, id, name)
        @id           = id
        @name         = name
        @client       = client
      end

      def sorted_environments
        environments.keys.sort
      end

      def environments
        @environments ||= couplings.each_with_object({}) do |part, sum|
          sum[part.stage] ||= []
          sum[part.stage].push(part)
          sum
        end
      end

      def environment_hash
        sorted_environments.each_with_object({}) do |environment, sum|
          sum[environment.to_sym] = environments[environment].map(&:to_hash)
          sum
        end
      end

      def to_hash
        {
          id: id,
          name: name,
          github_repository: github_repository,
          environments: environment_hash
        }
      end

      def configured?
        couplings.any? && github_repository
      end

      def github_repository
        remote_repository["repository"] &&
          remote_repository["repository"]["name"]
      end

      def couplings
        @couplings ||= remote_couplings_without_test_stage
      end

      def remote_couplings_without_test_stage
        remote_couplings.reject { |coupling| coupling.stage == "test" }
      end

      def remote_couplings
        client.heroku.get("/pipelines/#{id}/pipeline-couplings").map do |pc|
          Escobar::Heroku::Coupling.new(client, pc)
        end
      end

      def default_environment
        sorted_environments.last
      end

      def default_branch
        github_client.default_branch
      end

      def required_commit_contexts(forced = false)
        return [] if forced
        github_client.required_contexts.map do |context|
          if context == "continuous-integration/travis-ci"
            context = "continuous-integration/travis-ci/push"
          end
          context
        end
      end

      def heroku_permalink
        "https://dashboard.heroku.com/pipelines/#{id}"
      end

      def default_branch_settings_uri
        "https://github.com/#{github_repository}/" \
          "settings/branches/#{default_branch}"
      end

      def reap_build(app_id, build_id)
        build = Escobar::Heroku::Build.new(client, app_id, build_id)
        case build.status
        when "succeeded", "failed"
          build
        end
      end

      def reap_release(app_id, build_id, release_id)
        release = Escobar::Heroku::Release.new(
          client, app_id, build_id, release_id
        )
        case release.status
        when "succeeded", "failed"
          release
        end
      end

      def default_heroku_application(environment)
        app = environments[environment] && environments[environment].first
        unless app
          raise ArgumentError, "No '#{environment}' environment for #{name}."
        end
        app.app
      end

      def heroku_application_by_environment_and_name(stage, name)
        environments[stage].find do |app|
          return app.app if name == app.app.name
        end
      end

      def create_deployment(ref, environment, force = false, payload = {})
        heroku_app = default_heroku_application(environment)

        build_request = heroku_app.build_request_for(self)
        heroku_build = build_request.create(
          "deploy", environment, ref, force, payload
        )

        heroku_build
      end

      # source: A Escobar::Heroku::App to promote from
      # targets: An array of Escobar::Heroku::App to promote to
      # environment: The pipeline stage applying to the promotion
      # force: true if github commit status checks shouldn't be verified
      # payload: Extra info to insert into the github deployment API
      # second_factor: an OTP credential for protected resources
      # rubocop:disable Metrics/ParameterLists
      # rubocop:disable Metrics/LineLength
      def promote(source, targets, environment, force = false, payload = {}, second_factor = nil)
        promotion_request = Escobar::Heroku::PipelinePromotionRequest.new(
          client, self, source, targets, second_factor
        )
        promotion_request.create(environment, force, payload)
      end
      # rubocop:enable Metrics/ParameterLists
      # rubocop:enable Metrics/LineLength

      def get(path)
        response = kolkrabbi_client.get do |request|
          request.url path
          request.headers["Content-Type"]  = "application/json"
          request.headers["Authorization"] = "Bearer #{client.heroku.token}"
        end

        JSON.parse(response.body)
      end

      def kolkrabbi_client
        @kolkrabbi ||= if Escobar.zipkin_enabled?
                         kolkrabbi_zipkin_client
                       else
                         kolkrabbi_default_client
                       end
      end

      def kolkrabbi_zipkin_client
        Faraday.new(url: "https://#{kolkrabbi_hostname}") do |c|
          c.use :instrumentation
          c.use ZipkinTracer::FaradayHandler, kolkrabbi_hostname
          c.adapter Faraday.default_adapter
        end
      end

      def kolkrabbi_default_client
        Faraday.new(url: "https://#{kolkrabbi_hostname}")
      end

      def create_deployment_status(url, payload)
        github_client.create_deployment_status(url, payload)
      end

      def kolkrabbi_hostname
        ENV.fetch("KOLKRABBI_HOSTNAME", "kolkrabbi.heroku.com")
      end

      private

      def remote_repository
        @remote_repository ||= get("/pipelines/#{id}/repository")
      end

      def custom_deployment_payload
        { name: name, pipeline: self.to_hash, provider: "slash-heroku" }
      end

      def create_github_deployment_status(url, target_url, state, description)
        payload = {
          state: state,
          target_url: target_url,
          description: description
        }
        create_deployment_status(url, payload)
      end

      def github_client
        @github_client ||= Escobar::GitHub::Client.new(client.github_token,
                                                       github_repository)
      end
    end
  end
end
