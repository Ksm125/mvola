# frozen_string_literal: true

module MVola
  class Transaction
    # Class that represents the status of a transaction.
    # It is used as return value of the `initiate_payment!` and the status of a transaction.
    # This is aimed to be used internally, and not exposed to the public API.
    class Status
      extend Forwardable

      attr_reader :raw_response, :client_correlation_id

      # raw_response is a hash data returned from the API
      def initialize(raw_response, client_correlation_id:)
        @raw_response = raw_response
        @client_correlation_id = client_correlation_id
      end

      def status
        raw_response["status"]
      end

      def server_correlation_id
        raw_response["serverCorrelationId"]
      end

      def notification_method
        raw_response["notificationMethod"]
      end

      def transaction_reference
        raw_response["objectReference"]
      end

      def pending?
        status == "pending"
      end

      def completed?
        status == "completed"
      end

      def failed?
        status == "failed"
      end
    end
  end
end
