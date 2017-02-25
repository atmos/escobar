module Escobar
  # Top-level client for heroku
  class Client
    # TimeoutError class when API timeouts
    class TimeoutError < StandardError
      def self.wrap(err)
        new(err)
      end

      attr_reader :cause
      def initialize(err)
        @cause = err
        self.set_backtrace(err.backtrace)
      end
    end

    # Class for returning API errors to escobar clients
    class HTTPError < StandardError
      attr_accessor :body, :headers, :status
      def self.from_response(err)
        error = new("Error from Heroku API")

        error.body    = err.response[:body]
        error.headers = err.response[:headers]
        error.status  = err.response[:status]

        error.set_backtrace(err.backtrace)
        error
      end
    end

    def self.from_environment
      new(Escobar.github_api_token, Escobar.heroku_api_token)
    end

    attr_reader :github_token, :heroku
    def initialize(github_token, heroku_token)
      @github_token = github_token
      @heroku = Escobar::Heroku::Client.new(heroku_token)
    end

    # mask password
    def inspect
      inspected = super
      inspected = inspected.gsub! @github_token, "*******" if @github_token
      inspected
    end

    def [](key)
      pipelines.find { |pipeline| pipeline.name == key }
    end

    def app_names
      pipelines.map(&:name)
    end

    def pipelines
      @pipelines ||= heroku.get("/pipelines").map do |pipe|
        Escobar::Heroku::Pipeline.new(self, pipe["id"], pipe["name"])
      end
    end
  end
end
