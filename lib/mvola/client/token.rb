# frozen_string_literal: true

module MVola
  class Client
    Token = Struct.new(:access_token, :scope, :token_type, :expires_at, keyword_init: true) do
      def expired?
        Time.now >= expires_at - expires_margin
      end

      private

      # Add a margin to the expiration time to avoid using an expired token.
      def expires_margin
        5 * 60 # 5 minutes
      end
    end
  end
end
