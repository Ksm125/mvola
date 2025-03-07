# frozen_string_literal: true

require_relative "client"
require_relative "transaction/status"
require_relative "transaction/details"

module MVola
  class Transaction
    include Request

    API_VERSION = "1.0.0"
    ENDPOINT = "mvola/mm/transactions/type/merchantpay/#{API_VERSION}"
    CURRENCY = "Ar"
    NOT_ALLOWED_CHARACTERS_REGEXP = /[^\w\s\-._,]/

    attr_reader :client

    def initialize(client: nil)
      @client = client || Client.new
    end

    # Initiate a payment from a debit phone number to a credit phone number.
    # @param [Number | String] amount the amount to transfer.
    # Make sure to provide a non-decimal amount as MVola does not support decimal amounts (e.g.1000 for 1000Ar)
    # @param [String] debit_phone_number the phone number to debit.
    # Must be one of the safe sandbox phone numbers in sandbox mode
    # @param [String] credit_phone_number the phone number to credit.
    # Must be one of the safe sandbox phone numbers in sandbox mode
    # @param [String] client_transaction_reference
    # @param [String] original_transaction_reference the original transaction reference.
    #   Defaults to the `client_transaction_reference` if not provided
    # @param [String] client_correlation_id the client correlation ID. Defaults to a random UUID
    # @param [String] description the description of the payment.
    # Max 50 characters long without special character except: ["-", ".", "_", ","]
    # @param [String] callback_url the callback URL to use for the payment
    # @param [Array<Hash>] metadata additional metadata to use for the payment.
    # @example: [{ key: "fc", value: "USD" }, { key: "amountFc", value: "1" }]
    def initiate_payment!(amount:,
      debit_phone_number:,
      credit_phone_number:,
      client_transaction_reference:,
      description:, original_transaction_reference: client_transaction_reference,
      client_correlation_id: SecureRandom.uuid,
      callback_url: nil,
      metadata: [])

      if client.sandbox?
        raise ArgumentError, "debit_phone_number must be one of #{Client::SAFE_SANDBOX_PHONE_NUMBERS} in sandbox mode" unless Client::SAFE_SANDBOX_PHONE_NUMBERS.include?(debit_phone_number)
        raise ArgumentError, "credit_phone_number must be one of #{Client::SAFE_SANDBOX_PHONE_NUMBERS} in sandbox mode" unless Client::SAFE_SANDBOX_PHONE_NUMBERS.include?(credit_phone_number)
      end

      ensure_valid_sandbox_phone_number!(debit_phone_number, "debit_phone_number")
      ensure_valid_sandbox_phone_number!(credit_phone_number, "credit_phone_number")
      ensure_valid_description!(description)

      payload = {
        amount: amount.to_s,
        currency: CURRENCY,
        descriptionText: description.to_s,
        requestDate: Time.now.strftime("%Y-%m-%dT%H:%M:%S.%LZ"),
        requestingOrganisationTransactionReference: client_transaction_reference,
        originalTransactionReference: original_transaction_reference,
        debitParty: [{key: "msisdn", value: debit_phone_number}],
        creditParty: [{key: "msisdn", value: credit_phone_number}],
        metadata: [{key: "partnerName", value: client.partner_name}, *metadata]
      }
      headers = build_headers(client_correlation_id: client_correlation_id, callback_url: callback_url)
      logger.debug "Initiating payment with payload: #{payload}"
      response = post(url_for, json: payload, headers: headers)
      logger.debug "Payment initiated. Response: #{response.body}"

      parsed_body = JSON.parse(response.body)
      Status.new(parsed_body, client_correlation_id: client_correlation_id)
    end

    # Get the status of a payment using the server correlation ID.
    # This can be used to poll the status of a payment.
    def get_status(server_correlation_id, client_correlation_id: SecureRandom.uuid)
      url = url_for("status/#{server_correlation_id}")

      headers = build_headers(client_correlation_id: client_correlation_id)
      response = get(url, headers: headers)

      parsed_body = JSON.parse(response.body)
      Status.new(parsed_body, client_correlation_id: client_correlation_id)
    end

    # Get the details of a transaction using the transaction ID returned from the API.
    def get_details(transaction_id, client_correlation_id: SecureRandom.uuid)
      url = url_for(transaction_id)

      headers = build_headers(client_correlation_id: client_correlation_id)
      response = get(url, headers: headers)

      parsed_body = JSON.parse(response.body)
      Details.new(parsed_body, client_correlation_id: client_correlation_id)
    end

    private

    # Generate the URL for the given path by joining the base URL and the endpoint.
    def url_for(path = "")
      safe_path = path.gsub(/^\//, "") # Remove starting slash from the path (if any) to avoid incorrect URL generation
      Pathname.new(client.base_url).join(ENDPOINT, safe_path).to_s
    end

    def build_headers(client_correlation_id:, callback_url: nil)
      value = {
        "Authorization" => "Bearer #{client.token.access_token}",
        "Version" => "1.0",
        "X-CorrelationID" => client_correlation_id,
        "UserLanguage" => client.user_language,
        "Cache-Control" => "no-cache",
        "userAccountIdentifier" => "msisdn;#{client.partner_phone_number}",
        "partnerName" => client.partner_name
      }

      value["X-Callback-URL"] = callback_url if callback_url

      value
    end

    def ensure_valid_sandbox_phone_number!(phone_number, param_name = "phone_number")
      return unless client.sandbox?
      return if phone_number.empty?
      return if Client::SAFE_SANDBOX_PHONE_NUMBERS.include?(phone_number)

      raise ArgumentError, "#{param_name} must be one of #{Client::SAFE_SANDBOX_PHONE_NUMBERS} in sandbox mode"
    end

    def ensure_valid_description!(description)
      raise ArgumentError, "description is required" if description.blank?
      raise ArgumentError, "description must be 50 characters long maximum" if description.size > 50

      invalid_chars = description.match(NOT_ALLOWED_CHARACTERS_REGEXP)
      raise ArgumentError, "description contains invalid characters: #{invalid_chars}" if invalid_chars
    end
  end
end
