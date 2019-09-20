# frozen_string_literal: true

require 'spec_helper'

describe DesignManagement::BackfillVersionDataService do
  describe '.execute' do
    set(:author) { create(:user) }
    let(:batching_service) { DesignManagement::BackfillVersionDataBatchService }

    subject { described_class.execute }

    it 'selects versions with missing author_id' do
      version = create(:design_version)
      version.update_column(:author_id, nil)

      expect(batching_service).to receive(:new).once.and_call_original

      subject
    end

    it 'selects versions with missing created_at' do
      version = create(:design_version, author: author)
      version.update_column(:created_at, nil)

      expect(batching_service).to receive(:new).once.and_call_original

      subject
    end

    it 'does not select versions with author_id and created_at' do
      version = create(:design_version, author: author)

      expect(version.author_id).not_to be_nil
      expect(version.created_at).not_to be_nil
      expect(batching_service).not_to receive(:new)

      subject
    end

    it 'batches per issue' do
      # Create 3 versions in 2 issues
      issue_1, issue_2 = create_list(:issue, 2)
      create_list(:design_version, 2, issue: issue_1)
      create(:design_version, issue: issue_2)

      ::DesignManagement::Version.update_all(author_id: nil)

      expect(batching_service).to receive(:new).once.with(issue_1.id).and_call_original
      expect(batching_service).to receive(:new).once.with(issue_2.id).and_call_original

      subject
    end
  end
end
