# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ElasticsearchIndexedProject do
  before do
    stub_ee_application_setting(elasticsearch_indexing: true)
  end

  it_behaves_like 'an elasticsearch indexed container' do
    let(:container) { :elasticsearch_indexed_project }
    let(:attribute) { :project_id }
    let(:index_action) do
      expect(ElasticIndexerWorker).to receive(:perform_async).with(:index, 'Project', subject.project_id, any_args)
    end
    let(:delete_action) do
      expect(ElasticIndexerWorker).to receive(:perform_async).with(:delete, 'Project', subject.project_id, any_args)
    end
  end
end
