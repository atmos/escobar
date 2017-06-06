module Escobar
  # Top-level class for interacting with Heroku API
  module Heroku
    # Top-level client for interacting with Heroku API
    class Client
      attr_reader :token
      def initialize(token)
        @token = token
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
        response = with_error_handling do
          client.get do |request|
            request.url path
            request_defaults(request, version)
          end
        end
        JSON.parse(response.body)
      end

      def get_range(path, range, version = 3)
        response = with_error_handling do
          client.get do |request|
            request.url path
            request_defaults(request, version)
            request.headers["Range"] = range
          end
        end
        JSON.parse(response.body)
      end

      def post(path, body, second_factor = nil)
        response = with_error_handling do
          client.post do |request|
            request.url path
            request_defaults(request)
            if second_factor
              request.headers["Heroku-Two-Factor-Code"] = second_factor.to_s
            end
            request.body = body.to_json
          end
        end
        JSON.parse(response.body)
      end

      def put(path, body, second_factor = nil, version = 3)
        response = with_error_handling do
          client.put do |request|
            request.url path
            request_defaults(request, version)
            if second_factor
              request.headers["Heroku-Two-Factor-Code"] = second_factor.to_s
            end
            request.body = body.to_json
          end
        end
        JSON.parse(response.body)
      end

      private

      def with_error_handling
        resp = yield
        raise_on_status(resp)
        resp
      rescue Net::OpenTimeout, Faraday::TimeoutError,
             Faraday::Error::ConnectionFailed => e
        raise Escobar::Client::TimeoutError.wrap(e)
      rescue Faraday::Error::ClientError => e
        raise Escobar::Client::HTTPError.from_error(e)
      end

      def raise_on_status(resp)
        case resp.status
        when 401
          body = JSON.parse(resp.body)
          raise Escobar::Client::Error::SecondFactor.from_response(resp) \
            if body["message"]&.match(/factor/)
          raise Escobar::Client::Error::Unauthorized.from_response(resp)
        end
      end

      def client
        @client ||= Escobar.zipkin_enabled? ? zipkin_client : default_client
      end

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
