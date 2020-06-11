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
      expect(Elastic::ProcessBookkeepingService).to receive(:track!).with(subject.project)
    end
    let(:delete_action) do
      expect(ElasticDeleteProjectWorker).to receive(:perform_async).with(subject.project.id, subject.project.es_id)
    end
  end
end
