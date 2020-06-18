# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Elastic::ClusterReindexingService, :elastic do
  subject { described_class.new }

  let!(:settings) { create(:application_setting) }

  context 'job is not in progress' do
    before do
      allow(subject).to receive(:current_job).and_return(nil)
    end

    context 'stage: initial' do
      it 'raises and error when there is not enough space' do
        allow(Gitlab::Elastic::Helper.default).to receive(:index_size_bytes).and_return(100.megabytes)
        allow(Gitlab::Elastic::Helper.default).to receive(:cluster_free_size_bytes).and_return(30.megabytes)

        expect { subject.execute }.to raise_error(StandardError, /storage available/)
      end

      it 'pauses elasticsearch indexing' do
        expect { subject.execute }.to change { ApplicationSetting.current.elasticsearch_pause_indexing }.from(false).to(true)
      end
    end

    context 'stage: indexing' do
      it 'triggers reindexing' do
        allow(Gitlab::Elastic::Helper.default).to receive(:create_empty_index).and_return('new_index_name')
        allow(Gitlab::Elastic::Helper.default).to receive(:reindex).and_return('task_id')

        job = subject.execute(stage: :indexing)

        expect(job[:index_name]).to eq('new_index_name')
        expect(job[:task_id]).to eq('task_id')
      end
    end

    context 'stage: final' do
      it 'raises and error when job is not started' do
        expect { subject.execute(stage: :final) }.to raise_error(StandardError, /is not started/)
      end
    end
  end

  context 'job is in progress' do
    let(:job_info) do
      {
        old_index_name: 'old_index',
        index_name: 'new_index',
        documents_count: 10,
        task_id: 'task_id'
      }
    end

    before do
      allow(subject).to receive(:current_job).and_return(job_info)
      allow(Gitlab::Elastic::Helper.default).to receive(:task_status).and_return({ 'completed' => true })
      allow(Gitlab::Elastic::Helper.default).to receive(:refresh_index).and_return(true)
      settings.update!(elasticsearch_pause_indexing: true)
    end

    context 'stage: initial' do
      it 'raises an error when another job is active' do
        expect { subject.execute }.to raise_error(StandardError, /another job/)
      end
    end

    context 'stage: final' do
      it 'raises an error if documents count is different' do
        expect(Gitlab::Elastic::Helper.default).to receive(:index_size).and_return('docs' => { 'count' => 15 })

        expect { subject.execute(stage: :final) }.to raise_error(StandardError, /count is different/)
      end

      it 'launches all stage steps' do
        expect(Gitlab::Elastic::Helper.default).to receive(:index_size).and_return('docs' => { 'count' => 10 })
        expect(Gitlab::Elastic::Helper.default).to receive(:update_settings)
        expect(Gitlab::Elastic::Helper.default).to receive(:switch_alias)
        expect(Gitlab::Elastic::Helper.default).to receive(:delete_index).twice

        expect { subject.execute(stage: :final) }.to change { ApplicationSetting.current.elasticsearch_pause_indexing }.from(true).to(false)
      end
    end
  end
end
