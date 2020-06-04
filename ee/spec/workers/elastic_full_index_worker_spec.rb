# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ElasticFullIndexWorker do
  subject { described_class.new }

  before do
    stub_ee_application_setting(elasticsearch_indexing: true)
  end

  it 'does nothing if ES disabled' do
    stub_ee_application_setting(elasticsearch_indexing: false)
    expect(Elastic::IndexRecordService).not_to receive(:new)

    subject.perform(1, 2)
  end

  describe 'indexing' do
    let(:projects) { create_list(:project, 3) }

    it 'indexes projects in range' do
      projects.each do |project|
        expect_next_instance_of(Elastic::IndexRecordService) do |service|
          expect(service).to receive(:execute).with(project, true).and_return(true)
        end
      end

      subject.perform(projects.first.id, projects.last.id)
    end

    it 'retries failed indexing' do
      projects.each do |project|
        expect_next_instance_of(Elastic::IndexRecordService) do |service|
          expect(service).to receive(:execute).with(project, true).and_raise(Elastic::IndexRecordService::ImportError)
        end
      end

      expect_next_instance_of(Elastic::IndexProjectsByIdService) do |service|
        expect(service).to receive(:execute).with(project_ids: projects.map(&:id))
      end

      subject.perform(projects.first.id, projects.last.id)
    end
  end
end
