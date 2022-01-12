require "habitat"
require "redis"
require "json"

# :nodoc:
module RedisStats
  VERSION = "0.1.0"

  Habitat.create do
    # redis connection
    setting redis : Redis | Redis::PooledClient
    # cache-key prefix
    setting prefix : String = "stats"
    # stats ttl
    setting ttl : Time::Span = 1.day
  end

  # Adds metric to Redis.
  def self.add(key : String, duration : Float64)
    parsed_values = values(key: key)
    parsed_values << NamedTuple.new(created_at: Time.local, duration: duration)

    settings.redis.hset(settings.prefix, key, parsed_values.to_json)
  end

  # Generates general statistics for all keys hashset.
  #
  # Returns array of hashes with stats.
  def self.stats : Hash(String, Hash(String, String))
    result = {} of String => Hash(String, String)

    keys.each do |key|
      data = _stats(key)

      result[key] = data if data
    end

    result
  end

  # Removes all expired statistics.
  def self.del_expired_stats
    keys.each { |key| _del_expired_stats(key: key) }
  end

  # Generates statistics for key in hashset.
  #
  # Returns hash with stats.
  private def self._stats(key : String) : Hash(String, String)
    values = values(key: key)
    return({} of String => String) unless values

    # 5m 30m 1day
    five = [] of Float64
    thirty = [] of Float64
    day = [] of Float64

    values.each do |value|
      five << value["duration"] if value["created_at"] > 5.minutes.ago
      thirty << value["duration"] if value["created_at"] > 30.minutes.ago
      day << value["duration"] if value["created_at"] > 1.day.ago
    end

    {
      "5m" => !five.empty? ? "#{(five.sum / five.size).round(2)}ms" : "",
      "30m" => !thirty.empty? ? "#{(thirty.sum / thirty.size).round(2)}ms" : "",
      "1d" => !day.empty? ? "#{(day.sum / day.size).round(2)}ms" : "",
      "max" => !day.empty? ? "#{day.max.round(2)}ms" : "",
      "min" => !day.empty? ? "#{day.min.round(2)}ms" : "",
      "count" => day.size.to_s
    }
  end

  # Removes all expired statistics for a specific key.
  private def self._del_expired_stats(key : String)
    parsed_values = values(key: key)
    parsed_values = parsed_values.select { |value| value["created_at"] > settings.ttl.ago }

    # пишем обновленную статистику
    settings.redis.hset(settings.prefix, key, parsed_values.to_json)
  end

  # Retrieves all values from Redis for a specific key.
  #
  # Returns array of named tuples with stats.
  private def self.values(key : String) : Array(NamedTuple(created_at: Time, duration: Float64))
    values = settings.redis.hget(settings.prefix, key)

    if values
      Array(NamedTuple(created_at: Time, duration: Float64)).from_json(values)
    else
      [] of NamedTuple(created_at: Time, duration: Float64)
    end
  end

  # Form array with all presented stats keys in Redis.
  #
  # Return array of string keys.
  private def self.keys
    index = 0

    settings.redis.hgetall(settings.prefix).compact_map do |v|
      if index % 2 != 0
        index += 1
        next
      end

      index += 1

      v.to_s
    end
  end
end
