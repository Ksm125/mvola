# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in MVola.gemspec
gemspec

gem "rake", "~> 13.0"
gem "jwt", "~> 2.9"
gem "public_suffix", "~> 4.0"

group :development, :test do
  gem "faker", "<= 2.22"
  gem "standard", "<= 1.37"
  gem "standard-performance", "<= 1.4"
end

group :development do
  gem "overcommit", "~> 0.62"
end

group :test do
  gem "webmock"
  gem "timecop"
  gem "rspec", "~> 3.0"
end
