# frozen_string_literal: true

require 'spec_helper'

describe SelfMonitoringProjectCreateWorker do
  let_it_be(:jid) { 'b5b28910d97563e58c2fe55f' }
  let_it_be(:data_key) { "self_monitoring_create_result:#{jid}" }

  describe '#perform' do
    let(:service_class) { Gitlab::DatabaseImporters::SelfMonitoring::Project::CreateService }
    let(:service) { instance_double(service_class) }
    let(:service_result) { { status: 'success', project_id: 2 } }

    before do
      allow(service_class).to receive(:new) { service }
      allow(service).to receive(:execute).and_return(service_result)

      allow(subject).to receive(:jid).and_return(jid)
    end

    it 'runs the SelfMonitoring::Project::CreateService' do
      expect(service).to receive(:execute)

      subject.perform
    end

    it 'writes output of service to cache' do
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

  describe '.status', :clean_gitlab_redis_shared_state do
    subject { described_class.status(jid) }

    it 'returns in_progress when job is enqueued' do
      jid = described_class.perform_async

      expect(described_class.status(jid)).to eq(status: :in_progress)
    end

    it 'returns status unknown with nil data' do
      expect(subject).to eq(
        status: :unknown,
        message: "Status of job with ID \"#{jid}\" could not be determined"
      )
    end

    it 'returns non nil data' do
      data = { status: 'success' }
      Gitlab::Redis::SharedState.with do |redis|
        redis.hset(data_key, *data.to_a.flatten)
      end

      expect(subject).to eq(status: :completed, output: data)
    end
  end
end
