# PagerDuty::Connection

PagerDuty::Connection is a Ruby wrapper for the [PagerDuty REST API](http://developer.pagerduty.com/documentation/rest)

It has a few design goals:

* be usable to someone familiar with Ruby
* be usable to someone familiar with the PagerDuty REST API, or at least able to read the documentation
* try to be future proof for API additions
* try not to do too much magic, in order to support the above

In the end, this is what it does:

* provides methods for each of the HTTP methods you can use on the API, that takes a path (like if you copied from the documentation), and a Hash of request parameters to send
* provide a simpler way to do pagination (pass `:page => ` to `get`), because using `limit` and `offset` using as [described by the API](http://developer.pagerduty.com/documentation/rest/pagination) is tedious in practice
* converts time-like strings in responses to `Time` objects, since that is what most people will do anyways
* converts time-like objects in requests to ISO 8601 strings, as this is documented as required by the API but is easy to forget and tedious to do anytime you use time parameters (ie `since` and `until`)
* detect 404 errors, and raise them as `PagerDuty::Connection::FileNotFoundError` errors
* detect [API errors](http://developer.pagerduty.com/documentation/rest/errors) and raise them as `PagerDuty::Connection::ApiError`

And this is what it doesn't do:

* provide first class objects for Incidents, Services, etc (they can change, and have new methods)
* provide an a ActiveResource interface (ActiveResource libraries can be hard to built wrappers for. Also, it's not conducive to accessing multiple pagerduty accounts)
* have methods for individual API calls that are possible (ie `find_incident`, `list_users`, etc)
* provide [will_paginate](https://github.com/mislav/will_paginate) or [kaminari](https://github.com/amatsuda/kaminari) paginated arrays (They aren't super documented for building a library that works well with them, and have different APIs)

## Installation

Add this line to your application's Gemfile:

    gem 'pager_duty-connection'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install pager_duty-connection

## Usage


Working code is worth a thousand words. The basics:

`` ruby
# setup the connection
pagerduty = PagerDuty::Connection.new(account, token)

# 4 main methods: get, post, put, and delete:

response = pagerduty.get('some/relative/path', :some => 'request', :parameter => 'to pass'
response = pagerduty.post('some/relative/path', :some => 'request', :parameter => 'to pass'
response = pagerduty.delete('some/relative/path', :some => 'request', :parameter => 'to pass'
response = pagerduty.put('some/relative/path', :some => 'request', :parameter => 'to pass'

# use something like irb or pry to poke around the responses
# the contents will vary a bit between call, ie:

response = pagerduty.get('incidents')
response.incidents # an array of incidents

response = pagerduty.get('incidents/YYZ')
response # the hash/object that represents the array
``

For more advanced and realistic examples, check out the examples directory:

* [shifts-with-incidents-and-log-entries](examples/shifts-with-incidents-and-log-entries.rb)
* [find-users](examples/find-users.rb)

In general, you can get/put/post/delete a path, with some attributes. Use the [REST API Documentation](http://developer.pagerduty.com/documentation/rest) to get some ideas

If you are working in Rails, and using only a single PagerDuty account, you'll probably want an initializer:

```ruby
$pagerduty = PagerDuty::Connection.new('your-subdomain', 'your-token')
```

And if you are using [dotenv](https://github.com/bkeepers/dotenv), you can use environment variables, and stash them in .env:

```ruby
account = ENV['PAGERDUTY_ACCOUNT'] || raise("Missing ENV['PAGERDUTY_ACCOUNT'], add to .env")
token = ENV['PAGERDUTY_TOKEN'] || raise("Missing ENV['PAGERDUTY_TOKEN'], add to .env.#{Rails.env}")
$pagerduty = PagerDuty::Connection.new(account, token)
```

## Questions and Answers

> What about the [pagerduty](https://github.com/envato/pagerduty) gem?

That is only for PagerDuty's [Integration API](http://developer.pagerduty.com/documentation/integration/events), ie for triggering/acknowleding/resolinv incidents

> What about the [pagerduty-full](https://github.com/gphat/pagerduty-full) gem?

It tries to be too clever and tightly models the API. For exampe, by having only Incident & Schedule classes, with specific methods for doing specific API calls, it means having to update the gem anytime new resources are added, and new API methods.

> What about [pagerduty_tools](https://github.com/precipice/pagerduty_tools)

That gem is less about being an API, and more about tools for being on call. Also, it took months for [my pull request to be reviewed](https://github.com/precipice/pagerduty_tools/pull/6), so didn't give me a lot of hope for changes making it in.

> Why not name it pagerduty-rest?

That would suggest a constant like Pagerduty::Rest, which I didn't like

> Why not name it pagerduty-connection?

That would suggest a constant like Pagerduty::Connection

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
