module Escobar
  module GitHub
    module Response
      # Faraday response middleware to handle API errors
      # This will translate status to Escobar::Client::Errors
      class RaiseError < ::Faraday::Response::Middleware
        private

        def on_complete(response)
          case response.status
          when 401
            raise Escobar::Client::Error::Unauthorized
              .from_response_env(response, "GitHub Unauthorized")
          end
        end
      end
    end
  end
end
