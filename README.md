# envconfig

An environment variable configuration mapper for Crystal. Uses syntax similar
to JSON, YAML, and DB shards to map environment variables to a Crystal class.
It's small.

Includes configuration printer for application startup as well.

### What Problem Does This Solve?

Containerized application or other 12-factor apps often rely on environment
variables to configure themselves. Repeatedly writing code to read variables
from `ENV[]` and then manually do type conversion, nil checking, etc is just
annoying. Other languages have packages for making this easy. Here's one for
Crystal. 

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     envconfig:
       github: relistan/envconfig.cr
   ```

2. Run `shards install`

## Usage

```crystal
require "envconfig"
```

```crystal
class TestConfig
  EnvConfig.mapping({
    prefix:      {type: String, default: "l/", nilable: false},
    redis_host:  {type: String, default: "localhost", nilable: false},
    redis_port:  {type: Int32,  default: "6379", nilable: false},
    redis_pool:  {type: Int32,  default: "200", nilable: false},
    listen_port: {type: Int32,  default: "8087", nilable: false},
    default_url: {type: String, nilable: false},
    ssl_urls:    {type: Bool,   default: "false", nilable: false},
    unset_thing: {type: Int64,  nilable: true}
    }, "TEST"
  )
end

config = TestConfig.new
puts config.redis_host

# OR dump all the values to a pretty-printed output
config.print_config()
```

The `mapping()` macro supports all the fields above, with the same meaning as
the `JSON` module in the stdlib.

The final argument to `mapping()` is a prefix to place in front of all your
environment variables to prevent namespace collisions.

### Printing Help Output

You may call the `help()` method to generate Usage information, including the
available settings and types, and their default values. It looks like this:

```
-------------------------------------------------------
Usage:
  The following vars apply. Types and defaults shown:

 * TEST_PREFIX (String) - l/
 * TEST_REDIS_HOST (String) - localhost
 * TEST_REDIS_PORT (Int32) - 6379
 * TEST_REDIS_POOL (Int32) - 200
 * TEST_LISTEN_PORT (Int32) - 8087
 * TEST_DEFAULT_URL (String) - *REQUIRED*
 * TEST_SSL_URLS (Bool) - false
 * TEST_UNSET_THING (Int64) - *NIL*
-------------------------------------------------------

```

Fields that are `nilable` and have no `default` show `*NIL*`, while those
without defaults that are _not_ `nilable` show `*REQUIRED*`.

### Printing Current Settings

Output from the pretty-printer `print_config()` looks like this:

```
Settings ---------------------------------------------
  *             prefix: "l/"
  *         redis_host: "localhost"
  *         redis_port: 6379
  *         redis_pool: 200
  *        listen_port: 8087
  *        default_url: "http://example.com/"
  *           ssl_urls: false
-------------------------------------------------------
```

This is useful when debugging what was actually set.

You may optionally pass a block to `print_config` that will be used to
obfuscate config values that should not be displayed. This is a block that will
be passed the key and value for each and is expected to return a string.
Something like:

```
config.print_config do |key, val|
  if key =~ /redis/
    "xxxx"
  else
    val.inspect
  end
end
```

## Contributing

1. Fork it (<https://github.com/your-github-user/envconfig/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Karl Matthias](https://github.com/relistan) - creator and maintainer
