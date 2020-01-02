# frozen_string_literal: true

require 'spec_helper'

describe ElasticsearchIndexedNamespace do
  before do
    stub_ee_application_setting(elasticsearch_indexing: true)
  end

  describe 'scope' do
    describe '.namespace_in' do
      let(:records) { create_list(:elasticsearch_indexed_namespace, 3) }

      it 'returns records of the ids' do
        expect(described_class.namespace_in(records.last(2).map(&:id))).to eq(records.last(2))
      end
    end
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

  context 'with plans' do
    Plan::PAID_HOSTED_PLANS.each do |plan|
      plan_factory = "#{plan}_plan"
      let_it_be(plan_factory) { create(plan_factory) }
    end

    let_it_be(:namespaces) { create_list(:namespace, 3) }
    let_it_be(:subscription1) { create(:gitlab_subscription, namespace: namespaces[2]) }
    let_it_be(:subscription2) { create(:gitlab_subscription, namespace: namespaces[0]) }
    let_it_be(:subscription3) { create(:gitlab_subscription, :silver, namespace: namespaces[1]) }

    before do
      stub_ee_application_setting(elasticsearch_indexing: false)
    end

    def get_indexed_namespaces
      described_class.order(:created_at).pluck(:namespace_id)
    end

    describe '.index_first_n_namespaces_of_plan' do
      it 'creates records, scoped by plan and ordered by namespace id' do
        ids = namespaces.map(&:id)
        expect(ElasticNamespaceIndexerWorker).to receive(:perform_async).with(ids[0], :index)

        described_class.index_first_n_namespaces_of_plan('gold', 1)

        expect(get_indexed_namespaces).to eq([ids[0]])
        expect(ElasticNamespaceIndexerWorker).to receive(:perform_async).with(ids[2], :index)

        described_class.index_first_n_namespaces_of_plan('gold', 2)

        expect(get_indexed_namespaces).to eq([ids[0], ids[2]])
        expect(ElasticNamespaceIndexerWorker).to receive(:perform_async).with(ids[1], :index)

        described_class.index_first_n_namespaces_of_plan('silver', 1)

        expect(get_indexed_namespaces).to eq([ids[0], ids[2], ids[1]])
      end
    end

    describe '.unindex_last_n_namespaces_of_plan' do
      before do
        described_class.index_first_n_namespaces_of_plan('gold', 2)
        described_class.index_first_n_namespaces_of_plan('silver', 1)
      end

      it 'creates records, scoped by plan and ordered by namespace id' do
        ids = namespaces.map(&:id)

        expect(get_indexed_namespaces).to eq([ids[0], ids[2], ids[1]])
        expect(ElasticNamespaceIndexerWorker).to receive(:perform_async).with(ids[2], :delete)

        described_class.unindex_last_n_namespaces_of_plan('gold', 1)

        expect(get_indexed_namespaces).to eq([ids[0], ids[1]])
        expect(ElasticNamespaceIndexerWorker).to receive(:perform_async).with(ids[1], :delete)

        described_class.unindex_last_n_namespaces_of_plan('silver', 1)

        expect(get_indexed_namespaces).to eq([ids[0]])
        expect(ElasticNamespaceIndexerWorker).to receive(:perform_async).with(ids[0], :delete)

        described_class.unindex_last_n_namespaces_of_plan('gold', 1)

        expect(get_indexed_namespaces).to be_empty
      end
    end
  end
end
