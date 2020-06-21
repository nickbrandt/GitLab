# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ElasticFullIndexWorker do
  subject { described_class.new }

  before do
    stub_ee_application_setting(elasticsearch_indexing: true)
  end

  it 'does nothing if ES disabled' do
    stub_ee_application_setting(elasticsearch_indexing: false)
    expect(Gitlab::Elastic::BulkIndexer::InitialProcessor).not_to receive(:backfill_projects!)

    subject.perform(1, 2)
  end

  describe 'indexing' do
    let(:projects) { create_list(:project, 3) }

    it 'indexes projects in range' do
      expect(Gitlab::Elastic::BulkIndexer::InitialProcessor).to receive(:backfill_projects!).with(*projects)

      subject.perform(projects.first.id, projects.last.id)
    end
  end
end
