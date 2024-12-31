# frozen_string_literal: true

require_relative "client"

module MVola
  class Transaction
    include Request

    API_VERSION = "1.0.0"
    ENDPOINT = "mvola/mm/transactions/type/merchantpay/#{API_VERSION}"
    CURRENCY = "Ar"

    attr_reader :client

    def initialize(client: nil, user_language: "FR")
      @client = client || Client.new
    end

    def initiate_payment!(amount:,
      debit_phone_number:,
      credit_phone_number:,
      transaction_reference:,
      original_transaction_reference: transaction_reference,
      client_correlation_id: SecureRandom.uuid,
      description: nil,
      callback_url: nil,
      metadata: [])

      payload = {
        amount: amount.to_s,
        currency: CURRENCY,
        descriptionText: description,
        requestDate: Time.now.strftime("%Y-%m-%dT%H:%M:%S.%LZ"),
        requestingOrganisationTransactionReference: transaction_reference,
        originalTransactionReference: original_transaction_reference,
        debitParty: [{key: "msisdn", value: debit_phone_number}],
        creditParty: [{key: "msisdn", value: credit_phone_number}],
        metadata: [{key: "partnerName", value: client.partner_name}, *metadata]
      }
      logger.info "Initiating payment with payload: #{payload}"
      post url_for, json: payload, headers: headers(client_correlation_id: client_correlation_id, callback_url: callback_url)
    end

    def status(server_correlation_id, client_correlation_id: SecureRandom.uuid)
      url = url_for("status/#{server_correlation_id}")

      get url, headers: headers(client_correlation_id: client_correlation_id)
    end

    def details(transaction_id, client_correlation_id: SecureRandom.uuid)
      url = url_for(transaction_id)

      get url, headers: headers(client_correlation_id: client_correlation_id)
    end

    private

    # Generate the URL for the given path by joining the base URL and the endpoint.
    def url_for(path = "")
      safe_path = path.gsub(/^\//, "") # Remove  starting slash from the path (if any) to avoid incorrect URL generation
      Pathname.new(client.base_url).join(ENDPOINT, safe_path).to_s
    end

    def headers(client_correlation_id:, callback_url: nil)
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
  end
end
