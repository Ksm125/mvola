# MVola

![Build Status](https://github.com/Ksm125/mvola/actions/workflows/ruby.yml/badge.svg)

<img width="739" alt="Screenshot 2025-01-03 at 12 29 10" src="https://github.com/user-attachments/assets/2cb4f056-cf50-48df-a88b-7797bb289719" />


MVola is a Ruby gem that provides a simple way to interact with the [Mvola Payment API](https://mvola.mg/).

## Installation

Install the gem and add to the application's Gemfile by executing:

```bash
bundle add MVola
```

If bundler is not being used to manage dependencies, install the gem by executing:

```bash
gem install MVola
```

## Usage

before using the gem, ensure you have the credentials required to interact with the Mvola API (**Consumer Key** and **Consumer Secret**).

### Get Access Token

To get an access token, use the `MVola::Client` class and call the `token`

```ruby
client = MVola::Client.new(consumer_key: 'your_consumer_key', consumer_secret: 'your_consumer_secret')
# For sandbox environment, pass the sandbox option as true
# client = MVola::Client.new(consumer_key: 'your_consumer_key', consumer_secret: 'your_consumer_secret', sandbox: true)

client.token # <MVola::Client::Token access_token="your_access_token", token_type="Bearer", expires_at=2024-12-30 16:19:42 +0100, scope="EXT_INT_MVOLA_SCOPE">
```

The `token` method store the data at instance level, so that we when called multiple times, we don't have to request a new token each time, until the token expires.
If you want to force a new token, you can use the method:
```ruby
client.token!
```

#### Tips

We suggest that you store the token in cache system (like `Redis`) and passes the value directly into the client to avoid requesting a new token each time, across multiple instances of the application:
```ruby
token = client.token
# Store the value in cache
cache.write('mvola_token', token.to_h)

# then next time, you can use the value from cache
token = cache.read('mvola_token')
client = MVola::Client.new(consumer_key: 'your_consumer_key', consumer_secret: 'your_consumer_secret', token: token)

client.token # will use the provided token if it's still valid/not expired
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests.
You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.

To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/Ksm125/MVola.
This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/Ksm125/MVola/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the MVola project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/MVola/blob/main/CODE_OF_CONDUCT.md).
