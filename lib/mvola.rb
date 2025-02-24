# frozen_string_literal: true

require "logger"
require "base64"
require "time"
require "active_support"
require "active_support/core_ext"
require "active_support/inflector"
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
