# frozen_string_literal: true

require 'spec_helper'

describe SelfMonitoringProjectCreateWorker do
  let_it_be(:jid) { 'b5b28910d97563e58c2fe55f' }
  let_it_be(:in_progress_key) { "self_monitoring_create_in_progress:#{jid}" }
  let_it_be(:data_key) { "self_monitoring_create_result:#{jid}" }

  describe '#perform' do
    let(:service_class) { Gitlab::DatabaseImporters::SelfMonitoring::Project::CreateService }
    let(:service) { instance_double(service_class) }
    let(:service_result) { { status: :success, project: build(:project) } }

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
      expect(Rails.cache).to receive(:write)
      expect(Rails.cache).to receive(:write).with(data_key, service_result)

      subject.perform
    end

    it 'writes an in_progress key' do
      expect(Rails.cache).to receive(:write).with(in_progress_key, true)
      expect(Rails.cache).to receive(:write)
      expect(Rails.cache).to receive(:delete).with(in_progress_key)

      subject.perform
    end
  end

  describe '.status', :use_clean_rails_memory_store_caching do
    subject { described_class.status(jid) }

    it 'returns in_progress when in progress key present' do
      Rails.cache.write(in_progress_key, true)

      expect(subject).to eq(status: :in_progress)
    end

    it 'returns non nil data' do
      data = { status: :success, project_id: 1 }
      Rails.cache.write(data_key, data)

      expect(subject).to eq(status: :completed, output: data)
    end

    it 'returns status unknown with nil data' do
      Rails.cache.write(data_key, nil)

      expect(subject).to eq(
        status: :unknown,
        message: 'Job has not started as of yet or job_id is wrong'
      )
    end
  end
end
