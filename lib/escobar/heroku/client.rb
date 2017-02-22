module Escobar
  # Top-level class for interacting with Heroku API
  module Heroku
    # Top-level client for interacting with Heroku API
    class Client
      attr_reader :client, :token
      def initialize(token)
        @token = token
        @client = Escobar.zipkin_enabled? ? zipkin_client : default_client
      end

      # mask password
      def inspect
        inspected = super
        inspected = inspected.gsub! @token, "*******" if @token
        inspected
      end

      def user_information
        get("/account")
      end

      def get(path, version = 3)
        response = client.get do |request|
          request.url path
          request_defaults(request, version)
        end

        JSON.parse(response.body)
      rescue Net::OpenTimeout => e
        raise Escobar::Client::TimeoutError.new(e)
      rescue StandardError => e
        raise Escobar::Client::HTTPError.from_response(e, response)
      end

      def get_range(path, range, version = 3)
        response = client.get do |request|
          request.url path
          request_defaults(request, version)
          request.headers["Range"] = range
        end

        JSON.parse(response.body)
      rescue StandardError => e
        raise Escobar::Client::HTTPError.from_response(e, response)
      end

      def post(path, body)
        response = client.post do |request|
          request.url path
          request_defaults(request)
          request.body = body.to_json
        end

        JSON.parse(response.body)
      rescue StandardError => e
        raise Escobar::Client::HTTPError.from_response(e, response)
      end

      def put(path, second_factor = nil)
        response = client.put do |request|
          request.url path
          request_defaults(request)
          if second_factor
            request.headers["Heroku-Two-Factor-Code"] = second_factor
          end
        end

        JSON.parse(response.body)
      rescue StandardError => e
        raise Escobar::Client::HTTPError.from_response(e, response)
      end

      private

      def request_defaults(request, version = 3)
        request.headers["Accept"]          = heroku_accept_header(version)
        request.headers["Accept-Encoding"] = ""
        request.headers["Content-Type"]    = "application/json"
        if token
          request.headers["Authorization"] = "Bearer #{token}"
        end
        request.options.timeout = Escobar.http_timeout
        request.options.open_timeout = Escobar.http_open_timeout
      end

      def heroku_accept_header(version)
        "application/vnd.heroku+json; version=#{version}"
      end

      def zipkin_client
        Faraday.new(url: "https://api.heroku.com") do |c|
          c.use :instrumentation
          c.use ZipkinTracer::FaradayHandler, "api.heroku.com"
          c.adapter Faraday.default_adapter
        end
      end

      def default_client
        Faraday.new(url: "https://api.heroku.com")
      end
    end
  end
end
