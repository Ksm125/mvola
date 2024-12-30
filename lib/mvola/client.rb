# frozen_string_literal: true

require "base64"
require "json"
require_relative "client/token"
require_relative "request"

module MVola
  class Client
    include Request

    SANDBOX_URL = "https://devapi.mvola.mg"
    PRODUCTION_URL = "https://api.mvola.mg"

    attr_reader :consumer_key, :consumer_secret, :sandbox
    alias_method :sandbox?, :sandbox

    def initialize(consumer_key:, consumer_secret:, sandbox: false)
      @consumer_key = consumer_key
      @consumer_secret = consumer_secret
      @sandbox = sandbox
      @mutex = Mutex.new
    end

    # Get the token. If the token is not valid, it will be refreshed.
    def token
      return @token if @token&.valid?

      @token = @mutex.synchronize do
        data = fetch_token
        expires_at = Time.now + data[:expires_in]
        token_data = data.except(:expires_in).merge(expires_at: expires_at)

        Token.new(**token_data)
      end
    end

    # Force the token to be refreshed, even if it is still valid.
    def token!
      @token = nil
      token
    end

    private

    # This method is used to determine the base URL for the API requests.
    def base_url
      sandbox? ? SANDBOX_URL : PRODUCTION_URL
    end

    def headers
      {
        "Authorization" => "Basic #{Base64.strict_encode64("#{consumer_key}:#{consumer_secret}")}",
        "Content-Type" => "application/x-www-form-urlencoded",
        "Cache-Control" => "no-cache"
      }
    end

    def fetch_token
      url = URI.join(base_url, "token").to_s
      body = {
        grant_type: "client_credentials",
        scope: "EXT_INT_MVOLA_SCOPE"
      }

      response = post(url, headers: headers, body: body)

      JSON.parse(response.body, symbolize_names: true)
    end
  end
end
