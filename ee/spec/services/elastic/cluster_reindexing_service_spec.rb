# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Elastic::ClusterReindexingService, :elastic do
  subject { described_class.new }

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
        expect { subject.execute }.to change { Gitlab::CurrentSettings.elasticsearch_pause_indexing }.from(false).to(true)
      end
    end

    context 'stage: indexing' do
      it 'triggers reindexing' do
        task = create(:reindexing_task, stage: :initial)

        allow(Gitlab::Elastic::Helper.default).to receive(:create_empty_index).and_return('new_index_name')
        allow(Gitlab::Elastic::Helper.default).to receive(:reindex).and_return('task_id')

        subject.execute(stage: :indexing)

        task = task.reload
        expect(task.index_name_to).to eq('new_index_name')
        expect(task.elastic_task).to eq('task_id')
        expect(task.reload.stage).to eq('indexing')
      end
    end

    context 'stage: final' do
      it 'raises and error when job is not started' do
        expect { subject.execute(stage: :final) }.to raise_error(StandardError, /performed after/)
      end
    end
  end

  context 'job is in progress' do
    before do
      allow(Gitlab::Elastic::Helper.default).to receive(:task_status).and_return({ 'completed' => true })
      allow(Gitlab::Elastic::Helper.default).to receive(:refresh_index).and_return(true)
    end

    context 'stage: final' do
      let(:task) { create(:reindexing_task, stage: :final, documents_count: 10) }

      it 'raises an error if documents count is different' do
        expect(Gitlab::Elastic::Helper.default).to receive(:index_size).and_return('docs' => { 'count' => task.documents_count * 2 })

        expect { subject.execute(stage: :final) }.to raise_error(StandardError, /count is different/)
      end

      it 'launches all stage steps' do
        expect(Gitlab::Elastic::Helper.default).to receive(:index_size).and_return('docs' => { 'count' => task.documents_count })
        expect(Gitlab::Elastic::Helper.default).to receive(:update_settings)
        expect(Gitlab::Elastic::Helper.default).to receive(:switch_alias)
        expect(Gitlab::Elastic::Helper.default).to receive(:delete_index).twice
        expect(Gitlab::CurrentSettings).to receive(:update!).with(elasticsearch_pause_indexing: false)

        expect { subject.execute(stage: :final) }.to change { task.reload.stage.to_sym }.from(:final).to(:success)
      end
    end
  end
end
