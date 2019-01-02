# Raw Webhook Agent

This is a fork of the default Webhook agent that accepts raw requests. It means that this agent will return raw request body instead of attempting to parse it as JSON or a query.

The exaple event is provided below.

```json
{
  "body": "<p>Hello World!</p>",
  "query": {
    "param1": "test",
    "param2": "123"
  }
}
```

## Installation

This gem is run as part of the [Huginn](https://github.com/huginn/huginn) project. If you haven't already, follow the [Getting Started](https://github.com/huginn/huginn#getting-started) instructions there.

Add this string to your Huginn's .env `ADDITIONAL_GEMS` configuration:

```ruby
huginn_raw_webhook_agent(github: TheDrHax/huginn_raw_webhook_agent)
```

## Contributing

1. Fork it ( https://github.com/TheDrHax/huginn_raw_webhook_agent/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
