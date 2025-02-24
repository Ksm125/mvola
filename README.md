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

We suggest that you store the token in cache system (like `Redis`, `Memcached`) and passes the value directly
into the client to avoid requesting a new token each time, across multiple instances of the application:

```ruby
token = client.token
# Store the value in cache
cache.write('mvola_token', token.to_h)

# then next time, you can use the value from cache
token = cache.read('mvola_token')

client = MVola::Client.new(consumer_key: 'your_consumer_key', consumer_secret: 'your_consumer_secret', token: token)

# If the token is still valid, the client will use it directly without requesting a new one.
# If it's expired, the client will automatically request a new one to make a request.
client.token
```

### Initialize a Payment

To initialize a payment, use the `MVola::Client` class and call the `init_payment!` method

```ruby
ENV["MVOLA_CONSUMER_KEY"] = "CONSUMER_KEY"
ENV["MVOLA_CONSUMER_SECRET"] = "CONSUMER_SECRET"
ENV["MVOLA_PARTNER_NAME"] = "PARTNER_NAME"

debit_phone_number = "0343500003"
credit_phone_number = "0343500004"

client = MVola::Client.new(sandbox: true)

transaction = MVola::Transaction.new(client: client)
# OR (if you want to use the default client)
# transaction = MVola::Transaction.new

client_transaction_reference = SecureRandom.hex
# Initiate a payment
response = transaction.initiate_payment!(amount: 2000,
                                         description: "attempting to make a test payment",
                                         debit_phone_number: debit_phone_number,
                                         credit_phone_number: credit_phone_number,
                                         client_transaction_reference: client_transaction_reference)

pp response
# => => #<MVola::Transaction::Status:0x000000010361ff90 @client_correlation_id="a029c8fa-d08f-4fd6-a62b-b53e419b3abe", @raw_response={"status"=>"pending", "serverCorrelationId"=>"3d894c69-d6c7-4ed7-8387-95351fb79657", "notificationMethod"=>"polling"}>

# Get the status of the payment
status_response = transaction.get_status(response.server_correlation_id)

pp status_response
# => => #<MVola::Transaction::Status:0x0000000103e51df8 @client_correlation_id="d6670863-b5a8-4998-8211-47c49498b466", @raw_response={"status"=>"completed", "serverCorrelationId"=>"3d894c69-d6c7-4ed7-8387-95351fb79657", "notificationMethod"=>"polling", "objectReference"=>"653815820"}>

# transaction_reference is the same as objectReference
details_response = transaction.get_details(status_response.transaction_reference)

pp details_response
# => #<MVola::Transaction::Details:0x0000000103cc0070
#     @client_correlation_id="44f4da6c-3844-4cb7-a563-bab3cce396a6",
#  @raw_response=
#   {"amount"=>"2000.00",
#    "currency"=>"Ar",
#    "request_date"=>"2025-02-24T18:16:27.674Z",
#    "debit_party"=>[{"key"=>"msisdn", "value"=>"0343500003"}],
#    "credit_party"=>[{"key"=>"msisdn", "value"=>"0343500004"}],
#    "fees"=>[{"fee_amount"=>"0"}],
#    "metadata"=>[{"key"=>"originalTransactionResult", "value"=>"0"}, {"key"=>"originalTransactionResultDesc", "value"=>"0"}],
#    "transaction_status"=>"completed",
#    "creation_date"=>"2025-02-24T15:14:07.810Z",
#    "transaction_reference"=>"653815826"}>

```

<details>

  <summary>Transaction Status and Details Structures</summary>

The `MVola::Transaction::Status` and `MVola::Transaction::Details` classes provide detailed information about transactions and their statuses.

### MVola::Transaction::Status

The `MVola::Transaction::Status` class provides information about the status of a transaction.

It includes the following attributes:

- `client_correlation_id`: A unique identifier for the client request.
- `raw_response`: The raw response from the MVola API, which includes:
  - `status`: The status of the transaction ("pending", "completed", "failed").
  - `serverCorrelationId`: A unique identifier for the server request.
  - `notificationMethod`: The method used for notifications (e.g., "polling").
  - `objectReference`: A reference to the transaction object.

### MVola::Transaction::Details

The `MVola::Transaction::Details` class provides detailed information about a transaction.

It includes the following attributes:

- `client_correlation_id`: A unique identifier for the client request.
- `raw_response`: The raw response from the MVola API, which includes:
  - `amount`: The amount of the transaction.
  - `currency`: The currency of the transaction.
  - `request_date`: The date the transaction was requested.
  - `debit_party`: Information about the debit party (e.g., phone number).
  - `credit_party`: Information about the credit party (e.g., phone number).
  - `fees`: Any fees associated with the transaction.
  - `metadata`: Additional metadata about the transaction.
  - `transaction_status`: The status of the transaction ("completed", "failed").
  - `creation_date`: The date the transaction was created.
  - `transaction_reference`: A reference to the transaction.

</details>

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
