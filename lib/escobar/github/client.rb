module Escobar
  module GitHub
    class RepoNotFound < StandardError; end
    # Top-level class for interacting with GitHub API
    class Client
      attr_reader :name_with_owner, :token
      def initialize(token, name_with_owner)
        @token           = token
        @name_with_owner = name_with_owner
      end

      # mask password
      def inspect
        inspected = super
        inspected = inspected.gsub! @token, "*******" if @token
        inspected
      end

      def whoami
        client.get("/user")
      end

      def archive_link(ref)
        path = "/repos/#{name_with_owner}/tarball/#{ref}"
        response = http_method(:head, path)
        response && response.headers && response.headers["Location"]
      end

      def not_found
        raise RepoNotFound, "Unable to access #{name_with_owner}"
      end

      def required_contexts
        path = "/repos/#{name_with_owner}/branches/#{default_branch}"
        response = http_method(:get, path)

        not_found unless response.status == 200

        repo = JSON.parse(response.body)
        return [] unless repo["protection"] && repo["protection"]["enabled"]
        repo["protection"]["required_status_checks"]["contexts"]
      end

      def default_branch
        response = http_method(:get, "/repos/#{name_with_owner}")
        not_found unless response.status == 200
        JSON.parse(response.body)["default_branch"]
      end

      def deployments
        response = http_method(:get, "/repos/#{name_with_owner}/deployments")
        not_found unless response.status == 200
        JSON.parse(response.body)
      end

      def create_deployment(options)
        body = {
          ref: options[:ref] || "master",
          task: options[:task] || "deploy",
          auto_merge: false,
          required_contexts: options[:required_contexts] || [],
          payload: options[:payload] || {},
          environment: options[:environment] || "staging",
          description: "Shipped from chat with slash-heroku"
        }
        post("/repos/#{name_with_owner}/deployments", body)
      end

      def create_deployment_status(url, payload)
        uri = URI.parse(url)
        post("#{uri.path}/statuses", payload)
      end

      def head(path)
        http_method(:head, path)
      end

      def get(path)
        response = http_method(:get, path)
        JSON.parse(response.body)
      end

      def accept_headers
        "application/vnd.github.loki-preview+json"
      end

      def http_method(verb, path)
        with_error_handling do
          client.send(verb) do |request|
            request.url path
            request.headers["Accept"] = accept_headers
            request.headers["Content-Type"] = "application/json"
            request.headers["Authorization"] = "token #{token}"
            request.options.timeout = Escobar.http_timeout
            request.options.open_timeout = Escobar.http_open_timeout
          end
        end
      end

      # rubocop:disable Metrics/AbcSize
      def post(path, body)
        with_error_handling do
          response = client.post do |request|
            request.url path
            request.headers["Accept"] = accept_headers
            request.headers["Content-Type"] = "application/json"
            request.headers["Authorization"] = "token #{token}"
            request.options.timeout = Escobar.http_timeout
            request.options.open_timeout = Escobar.http_open_timeout
            request.body = body.to_json
          end

          JSON.parse(response.body)
        end
      end
      # rubocop:enable Metrics/AbcSize

      private

      def with_error_handling
        yield
      rescue Net::OpenTimeout, Faraday::TimeoutError => e
        raise Escobar::Client::TimeoutError.wrap(e)
      rescue Faraday::Error::ClientError => e
        raise Escobar::Client::HTTPError.from_error(e)
      end

      def client
        @client ||= Escobar.zipkin_enabled? ? zipkin_client : default_client
      end

      def zipkin_client
        Faraday.new(url: "https://api.github.com") do |c|
          c.use :instrumentation
          c.use ZipkinTracer::FaradayHandler, "api.github.com"
          c.use Escobar::GitHub::Response::RaiseError
          c.adapter Faraday.default_adapter
        end
      end

      def default_client
        Faraday.new(url: "https://api.github.com") do |c|
          c.use Escobar::GitHub::Response::RaiseError
          c.adapter Faraday.default_adapter
        end
      end
    end
  end
end
