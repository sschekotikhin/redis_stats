[![Crystal CI](https://github.com/sschekotikhin/redis_stats/actions/workflows/crystal.yml/badge.svg?branch=master)](https://github.com/sschekotikhin/redis_stats/actions/workflows/crystal.yml)

# redis_stats

5m-30m-1d stats for tracking of code execution duration.

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     redis_stats:
       github: sschekotikhin/redis_stats
   ```

2. Run `shards install`

## Usage

```crystal
require "redis_stats"
```

### Basic example

```crystal
# configure
RedisStats.configure do |config|
  config.redis = Redis::PooledClient.new(
    host: "localhost",
    port: 6379,
    database: 0,
    pool_size: 10
  )
  config.ttl = 10.minutes
  config.prefix = "redis_stats"
end

# add method
t0 = Time.local

# ...
# some code
# ...

t1 = Time.local

# `key` - any string key
# `duration` - duration of executed code, milliseconds
RedisStats.add(key: "foo", duration: (t1 - t0).total_milliseconds)

# stats method
# Retrieves statistics from Redis.
RedisStats.stats
# => {
#   "foo" => {
#     "5m" => "0.3ms",   # last 5 minutes
#     "30m" => "0.5ms",  # last 30 minutes
#     "1d" => "0.55ms",  # last day
#     "max" => "0.7ms",  # max stored duration
#     "min" => "0.05ms", # min stored duration
#     "count" => "100"   # count of stored records
#   }
# }

# del_expired_stats method
# Removes all stats, which ttl expired.
RedisStats.del_expired_stats
```

## Contributing

1. Fork it (<https://github.com/sschekotikhin/redis_stats/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [SShekotihin](https://github.com/sschekotikhin) - creator and maintainer
