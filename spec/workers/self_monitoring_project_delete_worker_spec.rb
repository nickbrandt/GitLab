# frozen_string_literal: true

require 'spec_helper'

describe SelfMonitoringProjectDeleteWorker do
  let_it_be(:jid) { 'b5b28910d97563e58c2fe55f' }
  let_it_be(:data_key) { "self_monitoring_delete_result:#{jid}" }

  describe '#perform' do
    let(:service_class) { Gitlab::DatabaseImporters::SelfMonitoring::Project::DeleteService }
    let(:service) { instance_double(service_class) }
    let(:service_result) { { status: 'success', project_id: 2 } }

    it_behaves_like 'executes service and writes data to redis'
  end

  describe '.status', :clean_gitlab_redis_shared_state do
    subject { described_class.status(jid) }

    it_behaves_like 'returns status based on Sidekiq::Status and data in redis'
  end
end
