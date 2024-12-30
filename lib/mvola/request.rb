# frozen_string_literal: true

require "net/http"
require "forwardable"

module MVola
  module Request
    extend Forwardable

    def_delegators MVola, :logger

    # Method to perform a GET request
    # @param url [String] the URL to perform the request
    # @param args [Hash] the arguments to pass to the request
    # @option args [Hash] :params the parameters to pass to the request
    # @option args [Hash] :headers the headers to pass to the request
    def get(url, args = {})
      uri = URI.parse(url)
      headers = args.delete(:headers) || {}
      request = Net::HTTP::Get.new(uri.request_uri, headers)

      logger.debug("GET #{url} #{args}")
      response = build_http(uri, args).request(request)
      logger.debug("Response: #{response.code} #{response.body.inspect}")

      handle_error(response)

      response
    end

    # Method to perform a POST request
    # @param url [String] the URL to perform the request
    # @param args [Hash] the arguments to pass to the request
    # @option args [Hash] :params the parameters to pass to the request
    # @option args [Hash] :headers the headers to pass to the request
    # @option args [Hash] :body the body to pass to the request
    # @option args [Hash] :json the JSON to pass to the request body. Replace the body if present
    def post(url, args = {})
      uri = URI.parse(url)
      headers = args.delete(:headers) || {}
      headers["Content-Type"] = "application/json" if args.key?(:json)

      request = Net::HTTP::Post.new(uri.request_uri, headers)

      request.form_data = args[:body] if args[:body]
      if (json = args.delete(:json))
        request.body = json.to_json
      end

      logger.debug("POST #{url} #{args}")
      response = build_http(uri, args).request(request)
      logger.debug("Response: #{response.code} #{response.body.inspect}")

      handle_error(response)

      response
    end

    private

    def build_http(uri, args)
      uri.query = URI.encode_www_form(args[:params]) if args[:params]
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      http
    end

    def handle_error(response)
      case response.code.to_i
      when 200..299
        # Do nothing
      when 401
        raise MVola::Unauthorized, response.body
      else
        raise MVola::InvalidRequest, response.body
      end
    end
  end
end
