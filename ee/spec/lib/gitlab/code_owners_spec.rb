# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::CodeOwners do
  include FakeBlobHelpers

  let!(:code_owner) { create(:user, username: 'owner-1') }
  let(:project) { create(:project, :repository) }
  let(:codeowner_content) { "docs/CODEOWNERS @owner-1" }
  let(:codeowner_blob) { fake_blob(path: 'CODEOWNERS', data: codeowner_content) }
  let(:codeowner_blob_ref) { fake_blob(path: 'CODEOWNERS', data: codeowner_content) }

  before do
    project.add_developer(code_owner)
    allow(project.repository).to receive(:code_owners_blob)
      .with(ref: codeowner_lookup_ref)
      .and_return(codeowner_blob)
  end

  describe '.for_blob' do
    let(:branch) { TestEnv::BRANCH_SHA['with-codeowners'] }
    let(:blob) { project.repository.blob_at(branch, 'docs/CODEOWNERS') }
    let(:codeowner_lookup_ref) { branch }

    context 'when the feature is available' do
      before do
        stub_licensed_features(code_owners: true)
      end

      it 'returns users for a blob' do
        expect(described_class.for_blob(blob)).to include(code_owner)
      end
    end

    context 'when the feature is not available' do
      before do
        stub_licensed_features(code_owners: false)
      end

      it 'returns no users' do
        expect(described_class.for_blob(blob)).to be_empty
      end
    end
  end

  describe '.entries_for_merge_request' do
    let(:codeowner_lookup_ref) { merge_request.target_branch }
    let(:merge_request) do
      build(
        :merge_request,
        source_project: project,
        source_branch: 'feature',
        target_project: project,
        target_branch: 'with-codeowners'
      )
    end

    context 'when the feature is available' do
      before do
        stub_licensed_features(code_owners: true)
      end

      it 'returns owners for merge request' do
        expect(merge_request).to receive(:modified_paths).with(past_merge_request_diff: nil).and_return(['docs/CODEOWNERS'])

        entry = described_class.entries_for_merge_request(merge_request).first

        expect(entry.pattern).to eq('docs/CODEOWNERS')
        expect(entry.users).to eq([code_owner])
      end

      context 'when merge_request_diff is specified' do
        let(:merge_request_diff) { double(:merge_request_diff) }

        it 'returns owners at the specified ref' do
          expect(merge_request).to receive(:modified_paths).with(past_merge_request_diff: merge_request_diff).and_return(['docs/CODEOWNERS'])

          entry = described_class.entries_for_merge_request(merge_request, merge_request_diff: merge_request_diff).first

          expect(entry.users).to eq([code_owner])
        end
      end
    end
  end

  describe '.for_merge_request' do
    let(:codeowner_lookup_ref) { merge_request.target_branch }
    let(:merge_request) do
      build(
        :merge_request,
        source_project: project,
        source_branch: 'feature',
        target_project: project,
        target_branch: 'with-codeowners'
      )
    end

    context 'when the feature is available' do
      before do
        stub_licensed_features(code_owners: true)
      end

      it 'returns owners for merge request' do
        expect(merge_request).to receive(:modified_paths).with(past_merge_request_diff: nil).and_return(['docs/CODEOWNERS'])

        expect(described_class.for_merge_request(merge_request)).to eq([code_owner])
      end

      context 'when owner is merge request author' do
        let(:merge_request) { build(:merge_request, target_project: project, author: code_owner) }

        it 'excludes author' do
          expect(merge_request).to receive(:modified_paths).with(past_merge_request_diff: nil).and_return(['docs/CODEOWNERS'])

          expect(described_class.for_merge_request(merge_request)).to eq([])
        end
      end

      context 'when merge_request_diff is specified' do
        let(:merge_request_diff) { double(:merge_request_diff) }

        it 'returns owners at the specified ref' do
          expect(merge_request).to receive(:modified_paths).with(past_merge_request_diff: merge_request_diff).and_return(['docs/CODEOWNERS'])

          expect(described_class.for_merge_request(merge_request, merge_request_diff: merge_request_diff)).to eq([code_owner])
        end
      end
    end

    context 'when the feature is not available' do
      before do
        stub_licensed_features(code_owners: false)
      end

      it 'returns no users' do
        expect(described_class.for_merge_request(merge_request)).to eq([])
      end
    end
  end
end
