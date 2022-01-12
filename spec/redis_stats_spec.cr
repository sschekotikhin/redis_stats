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

  describe "#add" do
    # TODO: write specs
  end

  describe "#stats" do
    # TODO: write specs
  end

  describe "#del_expired_stats" do
    # TODO: write specs
  end
end
