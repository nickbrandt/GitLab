# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::UsageDataCounters::RedisCounter, :clean_gitlab_redis_shared_state do
  let(:redis_key) { 'foobar' }

  subject { Class.new.extend(described_class) }

  it 'counter is increased' do
    expect do
      subject.increment(redis_key)
    end.to change { subject.total_count(redis_key) }.by(1)
  end
end
