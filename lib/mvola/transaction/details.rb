# frozen_string_literal: true

module MVola
  class Transaction
    class Details
      attr_reader :raw_response, :client_correlation_id

      # @param [Hash] raw_response Hash data returned from the server
      # @example of response:
      #   {
      #     "amount"=>"10000.00",
      #     "currency"=>"Ar",
      #     "request_date"=>"2025-02-23T22:20:41.265Z",
      #     "debit_party"=>[{"key"=>"msisdn", "value"=>"0343500003"}],
      #     "credit_party"=>[{"key"=>"msisdn", "value"=>"0343500004"}],
      #     "fees"=>[{"feeAmount"=>"0"}],
      #     "metadata"=>[
      #       {"key"=>"originalTransactionResult", "value"=>"0"},
      #       {"key"=>"originalTransactionResultDesc", "value"=>"0"}
      #      ],
      #     "transaction_status"=>"completed",
      #     "creation_date"=>"2025-02-23T19:19:34.707Z",
      #     "transaction_reference"=>"653805064"
      #   }
      # @param [String] client_correlation_id
      def initialize(raw_response, client_correlation_id:)
        @raw_response = raw_response
        @client_correlation_id = client_correlation_id

        define_delegators
      end

      def completed?
        transaction_status == "completed"
      end

      def failed?
        transaction_status == "failed"
      end

      private

      # list of methods to delegate to raw_response["key"]
      DELEGATED_METHOD_NAMES = %i[
        amount
        currency
        request_date
        debit_party
        credit_party
        fees
        metadata
        transaction_status
        creation_date
        transaction_reference
      ].freeze

      # Define methods to delegate to raw_response["key"]
      def define_delegators
        DELEGATED_METHOD_NAMES.each do |method_name|
          self.class.send(:define_method, method_name) do
            raw_response[method_name.to_s]
          end
        end
      end
    end
  end
end
