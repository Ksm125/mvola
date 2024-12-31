# frozen_string_literal: true

require "logger"
require "base64"
require "json"
require "time"
require_relative "mvola/version"
require_relative "mvola/errors"
require_relative "mvola/client"
require_relative "mvola/transaction"

module MVola
  class << self
    attr_accessor :logger
  end

  # Set up a default logger
  self.logger = Logger.new($stdout) # Logs to the console
  logger.level = Logger::INFO  # Default log level
end
