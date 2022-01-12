require "./spec_helper"

describe RedisStats do
  it "configurable" do
    client = Redis::PooledClient.new(
      host: "localhost",
      port: 6379,
      database: 0,
      pool_size: 10
    )

    RedisStats.configure do |config|
      config.redis = client
      config.ttl = 10.minutes
      config.prefix = "redis_stats"
    end

    RedisStats.settings.redis.should eq client
    RedisStats.settings.ttl.should eq 10.minutes
    RedisStats.settings.prefix.should eq "redis_stats"
  end

  describe "methods" do
    before_each do
      redis = Redis.new(
        host: ENV["REDIS_HOST"]? || "localhost",
        port: ENV["REDIS_PORT"]? ? ENV["REDIS_PORT"].to_i : 6379,
        database: 0
      )

      RedisStats.configure(&.redis=(redis))

      redis.flushdb
    end

    describe "#add" do
      it "adds stats to redis" do
        RedisStats.add(key: "foo", duration: 0.1)

        Array(NamedTuple(created_at: Time, duration: Float64)).from_json(
          Redis.new(
            host: ENV["REDIS_HOST"]? || "localhost",
            port: ENV["REDIS_PORT"]? ? ENV["REDIS_PORT"].to_i : 6379,
            database: 0
          )
            .hget(RedisStats.settings.prefix, "foo")
            .to_s
        ).size.should be > 0
      end
    end

    describe "#stats" do
      it "returns data" do
        RedisStats.add(key: "foo", duration: 0.1)

        RedisStats.stats.keys.size.should eq 1
        RedisStats.stats.keys.first.matches?(/foo/).should eq true
        RedisStats.stats.should eq({
          "foo" => {
            "5m"    => "0.1ms",
            "30m"   => "0.1ms",
            "1d"    => "0.1ms",
            "max"   => "0.1ms",
            "min"   => "0.1ms",
            "count" => "1",
          },
        })
      end
    end

    describe "#del_expired_stats" do
      it "deletes old data" do
        # ttl in future for fast expiring
        RedisStats.settings.ttl = -10.minutes

        [1.0, 2.0].each { |i| RedisStats.add(key: "foo", duration: i) }
        old_stats = RedisStats.stats

        RedisStats.del_expired_stats

        old_stats["foo"]["count"].should eq "2"
        RedisStats.stats["foo"]["count"].should eq "0"
      end
    end
  end
end
