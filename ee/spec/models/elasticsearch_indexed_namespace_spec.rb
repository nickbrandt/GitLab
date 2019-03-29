# frozen_string_literal: true

require 'spec_helper'

describe ElasticsearchIndexedNamespace do
  before do
    stub_ee_application_setting(elasticsearch_indexing: true)
  end

  it_behaves_like 'an elasticsearch indexed container' do
    let(:container) { :elasticsearch_indexed_namespace }
    let(:attribute) { :namespace_id }
    let(:index_action) do
      expect(ElasticNamespaceIndexerWorker).to receive(:perform_async).with(subject.namespace_id, :index)
    end
    let(:delete_action) do
      expect(ElasticNamespaceIndexerWorker).to receive(:perform_async).with(subject.namespace_id, :delete)
    end
  end
end
