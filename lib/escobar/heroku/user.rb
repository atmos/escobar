module Escobar
  module Heroku
    # Class representing the owner of the token
    class User
      attr_reader :client
      def initialize(client)
        @client = client
      end

      def can_view_app?(app_id)
        can?("app", app_id, "view")
      end

      def can?(resource_type, resource_id, capability)
        body = {
          resource_type: resource_type,
          resource_id: resource_id,
          capability: capability
        }
        response = client.put("/users/~/capabilities",
                              body,
                              nil,
                              "3.capabilities")
        response["capabilities"][0]["capable"]
      end
    end
  end
end
