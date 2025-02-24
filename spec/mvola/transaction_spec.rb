# spec/mvola/transaction_spec.rb
# frozen_string_literal: true

require "rspec"
require "webmock/rspec"
require "timecop"
require_relative "../../lib/mvola/transaction"
require_relative "../../lib/mvola/client"

RSpec.describe MVola::Transaction do
  let(:consumer_key) { Faker::Alphanumeric.alpha(number: 20) }
  let(:consumer_secret) { Faker::Alphanumeric.alpha(number: 20) }
  let(:partner_name) { Faker::Company.name }
  let(:partner_phone_number) { "0343500003" }
  let(:token_data) do
    {
      access_token: JWT.encode(Faker::Alphanumeric.alpha(number: 20), nil, "none"),
      token_type: "Bearer",
      scope: "EXT_INT_MVOLA_SCOPE",
      expires_at: Time.now + 3600
    }
  end
  let(:client) do
    MVola::Client.new(
      consumer_key: consumer_key,
      consumer_secret: consumer_secret,
      partner_name: partner_name,
      partner_phone_number: partner_phone_number,
      token: token_data
    )
  end

  let(:transaction) { described_class.new(client: client) }
  let(:debit_phone_number) { "0343500003" }
  let(:credit_phone_number) { "0343500004" }
  let(:transaction_reference) { Faker::Internet.uuid }
  let(:amount) { 2000 }
  let(:description) { "Test payment" }
  let(:server_correlation_id) { Faker::Internet.uuid }
  let(:response_body) { {serverCorrelationId: server_correlation_id} }

  before do
    stub_request(:post, "https://api.mvola.mg/mvola/mm/transactions/type/merchantpay/1.0.0")
      .to_return(status: 200, body: response_body.to_json, headers: {"Content-Type" => "application/json"})

    stub_request(:get, "https://api.mvola.mg/mvola/mm/transactions/type/merchantpay/1.0.0/status/#{server_correlation_id}")
      .to_return(status: 200, body: response_body.to_json, headers: {"Content-Type" => "application/json"})
  end

  describe "#initiate_payment!" do
    let(:client_transaction_reference) { Faker::Internet.base64 }

    it "initiates a payment and returns the payment status" do
      payment_status = transaction.initiate_payment!(
        amount: amount,
        debit_phone_number: debit_phone_number,
        credit_phone_number: credit_phone_number,
        client_transaction_reference: client_transaction_reference,
        description: description
      )

      expect(payment_status).to be_a(MVola::Transaction::Status)
      expect(payment_status.server_correlation_id).not_to be_nil
    end

    it "Use the client_correlation_id parameter if it is provided" do
      client_correlation_id = Faker::Internet.uuid

      payment_status = transaction.initiate_payment!(
        amount: amount,
        debit_phone_number: debit_phone_number,
        credit_phone_number: credit_phone_number,
        client_transaction_reference: client_transaction_reference,
        description: description,
        client_correlation_id: client_correlation_id
      )

      expect(payment_status).to be_a(MVola::Transaction::Status)
      expect(payment_status.client_correlation_id).to eq(client_correlation_id)
    end
  end

  describe "#get_status" do
    it "gets the status of a payment" do
      payment_status = transaction.get_status(server_correlation_id)

      expect(payment_status).to be_a(MVola::Transaction::Status)
      expect(payment_status.server_correlation_id).to eq server_correlation_id
    end
  end

  describe "#get_details" do
    let(:response_body) do
      {
        "amount" => "10000.00",
        "currency" => "Ar",
        "requestDate" => "2025-02-23T22:20:41.265Z",
        "debitParty" => [{"key" => "msisdn", "value" => "0343500003"}],
        "creditParty" => [{"key" => "msisdn", "value" => "0343500004"}],
        "fees" => [{"feeAmount" => "0"}],
        "metadata" => [
          {"key" => "originalTransactionResult", "value" => "0"},
          {"key" => "originalTransactionResultDesc", "value" => "0"}
        ],
        "transactionStatus" => "completed",
        "creationDate" => "2025-02-23T19:19:34.707Z",
        "transactionReference" => transaction_reference
      }
    end

    before do
      stub_request(:get, "https://api.mvola.mg/mvola/mm/transactions/type/merchantpay/1.0.0/#{transaction_reference}")
        .to_return(status: 200, body: response_body.to_json, headers: {"Content-Type" => "application/json"})
    end

    it "gets the details of a payment" do
      payment_details = transaction.get_details(transaction_reference)

      expect(payment_details).to be_a(MVola::Transaction::Details)
      expect(payment_details.transaction_reference).to eq(transaction_reference)
    end
  end
end
