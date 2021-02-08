# frozen_string_literal: true

Gitlab::Experiment.configure do |config|
  config.define_singleton_method(:_default_cache) do
    Gitlab::Experiment::Cache::RedisHashStore.new(
      pool: ->(&block) { Gitlab::Redis::SharedState.with { |redis| block.call(redis) } }
    )
  end

  config.base_class = 'ApplicationExperiment'
  config.cache = config._default_cache
end
