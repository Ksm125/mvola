# frozen_string_literal: true

require_relative "client/token"
require_relative "request"

module MVola
  class Client
    include Request

    SANDBOX_URL = "https://devapi.mvola.mg"
    PRODUCTION_URL = "https://api.mvola.mg"
    SAFE_SANDBOX_PHONE_NUMBERS = %w[0343500003 0343500004].freeze

    USER_LANGUAGES = {
      fr: "FR",
      mg: "MG"
    }.freeze

    attr_reader :consumer_key, :consumer_secret, :partner_name, :partner_phone_number, :user_language, :sandbox
    alias_method :sandbox?, :sandbox

    # @param consumer_key [String] the consumer key provided by MVola for the application
    # @param consumer_secret [String] the consumer secret provided by MVola for the application
    # @param partner_name [String] the name of the partner account
    # @param partner_phone_number [String] the phone number of the partner account.
    #   This is replaced by a default value in the sandbox environment
    # @param sandbox [Boolean] whether to use the sandbox environment or not.
    # @param token [Hash, Token] a previous stored token to use for the client.
    #   If provided and that it is still valid, it will be used instead of fetching a new one.
    def initialize(consumer_key: ENV["MVOLA_CONSUMER_KEY"],
      consumer_secret: ENV["MVOLA_CONSUMER_SECRET"],
      partner_name: ENV["MVOLA_PARTNER_NAME"],
      partner_phone_number: ENV["MVOLA_PARTNER_PHONE_NUMBER"],
      sandbox: false,
      user_language: USER_LANGUAGES[:fr],
      token: nil)
      raise ArgumentError, "consumer_key is required" unless consumer_key
      raise ArgumentError, "consumer_secret is required" unless consumer_secret
      raise ArgumentError, "partner_name is required" unless partner_name

      raise ArgumentError, "partner_phone_number is required" unless partner_phone_number

      if sandbox && !SAFE_SANDBOX_PHONE_NUMBERS.include?(partner_phone_number)
        raise ArgumentError, "partner_phone_number must be one of #{SAFE_SANDBOX_PHONE_NUMBERS} in sandbox mode"
      end

      # Warn invalid user language if not one of the supported languages
      unless USER_LANGUAGES.key?(user_language.downcase.to_sym)
        logger.warn "Invalid user language: #{user_language}. Using default language: #{USER_LANGUAGES[:fr]}"
      end

      @consumer_key = consumer_key
      @consumer_secret = consumer_secret
      @partner_name = partner_name
      @partner_phone_number = partner_phone_number
      @sandbox = sandbox
      @token = build_token_from(token)
      @user_language = USER_LANGUAGES.fetch(user_language.downcase.to_sym, USER_LANGUAGES[:fr])
      @mutex = Mutex.new
    end

    # Get the token. If the token is not valid, it will be refreshed.
    def token
      return @token if @token&.valid?

      @mutex.synchronize do
        @token = build_token_from(fetch_token)
      end
    end

    # Force the token to be refreshed, even if it is still valid.
    def token!
      @token = nil
      token
    end

    # This method is used to determine the base URL for the API requests.
    def base_url
      sandbox? ? SANDBOX_URL : PRODUCTION_URL
    end

    private

    # This method is used to build a token object from a hash or a token object.
    def build_token_from(data)
      return data if data.is_a?(Token)
      return unless data.is_a?(Hash)

      hash = data.dup
      hash[:expires_at] ||= Time.now + hash.delete(:expires_in).to_i
      hash[:expires_at] = Time.parse(hash[:expires_at].to_s) if hash[:expires_at].is_a?(String)
      Token.new(**hash)
    end

    def headers
      {
        "Authorization" => "Basic #{Base64.strict_encode64("#{consumer_key}:#{consumer_secret}")}",
        "Content-Type" => "application/x-www-form-urlencoded",
        "Cache-Control" => "no-cache"
      }
    end

    # Perform a request to fetch a new token from the MVola API.
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
