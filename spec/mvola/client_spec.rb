# frozen_string_literal: true

require "rspec"

RSpec.describe MVola::Client do
  let(:consumer_key) { Faker::Alphanumeric.alpha(number: 20) }
  let(:consumer_secret) { Faker::Alphanumeric.alpha(number: 20) }
  let(:scope) { "EXT_INT_MVOLA_SCOPE" }

  let(:base_url) { MVola::Client::PRODUCTION_URL }
  let(:request) do
    stub_request(:post, "#{base_url}/token")
      .with(
        headers: {
          "Authorization" => "Basic #{Base64.strict_encode64("#{consumer_key}:#{consumer_secret}")}",
          "Cache-Control" => "no-cache"
        },
        body: {
          grant_type: "client_credentials",
          scope: scope
        }
      ).and_return(body: response_body.to_json)
  end

  let(:response_body) do
    {
      access_token: JWT.encode(Faker::Alphanumeric.alpha(number: 20), nil, "none"),
      token_type: "Bearer",
      scope: scope,
      expires_in: 3600
    }
  end

  subject(:client) do
    described_class.new(
      consumer_key: consumer_key,
      consumer_secret: consumer_secret
    )
  end

  before do
    request # Stub the request
  end

  describe "#token" do
    it "fetches a new token from provider if no token defined" do
      Timecop.freeze do
        token = client.token

        expect(request).to have_been_made.once
        expect(token).to be_a(MVola::Client::Token)

        expected_token_data = response_body.except(:expires_in).merge(expires_at: Time.now + response_body[:expires_in])

        expect(token).to eq(MVola::Client::Token.new(**expected_token_data))
      end
    end

    it "only fetches token once if called multiple times" do
      client.token
      client.token
      client.token

      expect(request).to have_been_made.once
    end

    it "refreshes the token if no longer valid" do
      token = client.token
      Timecop.travel(token.expires_at + 1) do
        client.token
      end

      expect(request).to have_been_made.twice
    end

    it "refreshes the token if expires margin is reached" do
      token = client.token
      expires_margin = 5 * 60 # 5 minutes
      Timecop.travel(token.expires_at - expires_margin) do
        client.token
      end

      expect(request).to have_been_made.twice
    end

    context "when sandbox is false" do
      let(:base_url) { MVola::Client::SANDBOX_URL }

      subject(:client) do
        described_class.new(
          consumer_key: consumer_key,
          consumer_secret: consumer_secret,
          sandbox: true
        )
      end

      it "fetches the token from the sandbox provider" do
        client.token

        expect(request).to have_been_made.once
      end
    end

    context "when token is provided" do
      subject(:client) do
        described_class.new(
          consumer_key: consumer_key,
          consumer_secret: consumer_secret,
          token: token
        )
      end

      context "when token is a hash" do
        let(:token) do
          {
            access_token: JWT.encode(Faker::Alphanumeric.alpha(number: 20), nil, "none"),
            token_type: "Bearer",
            scope: scope,
            expires_at: Time.now + 3600
          }
        end

        it "uses the provided token" do
          expect(client.token).to eq(MVola::Client::Token.new(**token))

          expect(request).not_to have_been_made
        end
      end

      context "when token is a Token object" do
        let(:token) do
          MVola::Client::Token.new(
            access_token: JWT.encode(Faker::Alphanumeric.alpha(number: 20), nil, "none"),
            token_type: "Bearer",
            scope: scope,
            expires_at: Time.now + 3600
          )
        end

        it "uses the provided token" do
          expect(client.token).to eq(token)

          expect(request).not_to have_been_made
        end
      end
    end
  end

  describe "#token!" do
    it "forces the token to be refreshed" do
      client.token
      client.token!

      expect(request).to have_been_made.twice
    end
  end
end
