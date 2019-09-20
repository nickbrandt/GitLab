# frozen_string_literal: true

require 'spec_helper'

describe DesignManagement::BackfillVersionDataBatchService do
  describe '#execute' do
    set(:issue) { create(:issue) }
    set(:project) { issue.project }

    subject { execute_service }

    def execute_service
      described_class.new(issue.id).execute
    end

    def create_versions_with_missing_data(num_records: 1)
      designs = create_list(:design, num_records, :with_file, issue: issue)
      DesignManagement::Version.update_all(author_id: nil, created_at: nil)

      designs.flat_map(&:versions)
    end

    it 'updates versions with the correct data' do
      version = create_versions_with_missing_data.first
      commit = project.design_repository.commit

      expect(commit.author).to be_present
      expect(commit.created_at).to be_present
      expect { subject }.to(
        change do
          version.reload
          [version.author_id, version.created_at]
        end
        .from([nil, nil])
        .to([commit.author.id, commit.created_at])
      )
    end

    it 'logs an error if commit cannot be found' do
      create_versions_with_missing_data

      expect_next_instance_of(DesignManagement::Repository) do |repo|
        expect(repo).to receive(:commits_by).and_return([])
      end
      expect(Gitlab::BackgroundMigration::Logger).to receive(:error).once.with(
        a_hash_including(message: 'No commit found for version')
      )

      subject
    end

    it 'loads all User records in a single batch' do
      create_versions_with_missing_data(num_records: 10)

      expect(User).to receive(:where).once.and_call_original

      subject
    end
  end
end
