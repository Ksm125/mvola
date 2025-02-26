# frozen_string_literal: true

module MVola
  class Error < StandardError; end

  class BadRequestError < Error; end

  class UnauthorizedError < Error; end

  class NotFoundError < Error; end

  class ServerError < Error; end

  class ApiError < Error; end
end
