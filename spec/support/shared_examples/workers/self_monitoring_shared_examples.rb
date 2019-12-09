# frozen_string_literal: true

# All examples require the following variables defined:
#   let_it_be(:jid) { 'b5b28910d97563e58c2fe55f' }
#   let_it_be(:data_key) { "self_monitoring_delete_result:#{jid}" }

# This shared_example requires the following variables:
#   let(:service_class) { Gitlab::DatabaseImporters::SelfMonitoring::Project::DeleteService }
#   let(:service) { instance_double(service_class) }
#   let(:service_result) { { status: :success, message: 'A message' } }
RSpec.shared_examples 'executes service and writes data to redis' do
  before do
    allow(service_class).to receive(:new) { service }
    allow(service).to receive(:execute).and_return(service_result)

    allow(subject).to receive(:jid).and_return(jid)
  end

  it do
    expect(service).to receive(:execute)

    Sidekiq::Testing.inline! do
      described_class.perform_async
    end
  end

  it 'writes output of service to redis' do
    subject.perform

    data = nil
    ttl = nil
    Gitlab::Redis::SharedState.with do |redis|
      ttl = redis.ttl(data_key)
      data = redis.hgetall(data_key)
    end

    expect(ttl).to be > 0
    expect(data).to eq(service_result.slice(:status, :message).stringify_keys)
  end
end

# This shared_example requires subject to be defined:
#   subject { described_class.status(jid) }
RSpec.shared_examples 'returns status based on Sidekiq::Status and data in redis' do
  it 'returns in_progress when job is enqueued', :clean_gitlab_redis_shared_state do
    jid = described_class.perform_async

    expect(described_class.status(jid)).to eq(status: :in_progress)
  end

  it 'returns status completed when data key has data' do
    data = { status: 'success' }
    Gitlab::Redis::SharedState.with do |redis|
      redis.hset(data_key, *data.to_a.flatten)
    end

    expect(subject).to eq(status: :completed, output: data)
  end

  it 'returns status unknown when data key has blank data' do
    expect(subject).to eq(
      status: :unknown,
      message: "Status of job with ID \"#{jid}\" could not be determined"
    )
  end
end
