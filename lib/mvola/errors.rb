# frozen_string_literal: true

module MVola
  class Error < StandardError; end

  class InvalidRequest < Error; end

  class Unauthorized < Error; end
end
