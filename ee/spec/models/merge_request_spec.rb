require 'spec_helper'

describe MergeRequest do
  using RSpec::Parameterized::TableSyntax

  let(:project) { create(:project, :repository) }

  subject(:merge_request) { create(:merge_request, source_project: project, target_project: project) }

  describe 'associations' do
    it { is_expected.to have_many(:approvals).dependent(:delete_all) }
    it { is_expected.to have_many(:approvers).dependent(:delete_all) }
    it { is_expected.to have_many(:approver_groups).dependent(:delete_all) }
    it { is_expected.to have_many(:approved_by_users) }
  end

  describe '#approvals_before_merge' do
    where(:license_value, :db_value, :expected) do
      true  | 5   | 5
      true  | nil | nil
      false | 5   | nil
      false | nil | nil
    end

    with_them do
      let(:merge_request) { build(:merge_request, approvals_before_merge: db_value) }

      subject { merge_request.approvals_before_merge }

      before do
        stub_licensed_features(merge_request_approvers: license_value)
      end

      it { is_expected.to eq(expected) }
    end
  end

  describe '#base_pipeline' do
    let!(:pipeline) { create(:ci_empty_pipeline, project: subject.project, sha: subject.diff_base_sha) }

    it { expect(subject.base_pipeline).to eq(pipeline) }
  end

  describe '#base_license_management_artifact' do
    before do
      allow(subject.base_pipeline).to receive(:license_management_artifact)
        .and_return(1)
    end

    it 'delegates to merge request diff' do
      expect(subject.base_license_management_artifact).to eq(1)
    end
  end

  describe '#head_license_management_artifact' do
    before do
      allow(subject.head_pipeline).to receive(:license_management_artifact)
        .and_return(1)
    end

    it 'delegates to merge request diff' do
      expect(subject.head_license_management_artifact).to eq(1)
    end
  end

  describe '#expose_license_management_data?' do
    before do
      allow(subject.head_pipeline).to receive(:expose_license_management_data?)
        .and_return(1)
    end

    it 'delegates to merge request diff' do
      expect(subject.expose_license_management_data?).to eq(1)
    end
  end
end
