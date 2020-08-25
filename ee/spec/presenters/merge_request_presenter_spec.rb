# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequestPresenter do
  using RSpec::Parameterized::TableSyntax

  let(:merge_request) { create(:merge_request, source_project: project) }
  let(:project) { create(:project, :repository) }
  let(:user) { project.creator }
  let(:approval_feature_available) { true }

  before do
    stub_config_setting(relative_url_root: '/gitlab')
    stub_licensed_features(merge_request_approvers: approval_feature_available)
  end

  shared_examples 'is nil when needed' do
    where(:approval_feature_available, :with_iid) do
      false | false
      false | true
      true  | false
    end

    with_them do
      before do
        merge_request.iid = nil unless with_iid
      end

      it { is_expected.to be_nil }
    end
  end

  describe '#api_approval_settings_path' do
    subject { described_class.new(merge_request, current_user: user).api_approval_settings_path }

    it_behaves_like 'is nil when needed'

    it { is_expected.to eq(expose_path("/api/v4/projects/#{merge_request.project.id}/merge_requests/#{merge_request.iid}/approval_settings")) }
  end

  describe '#api_project_approval_settings_path' do
    subject { described_class.new(merge_request, current_user: user).api_project_approval_settings_path }

    it { is_expected.to eq(expose_path("/api/v4/projects/#{merge_request.project.id}/approval_settings")) }

    context "when approvals not available" do
      let(:approval_feature_available) { false }

      it { is_expected.to be_nil }
    end
  end

  describe '#suggested_approvers' do
    subject { described_class.new(merge_request, current_user: user).suggested_approvers }

    it 'delegates to the approval state' do
      expect(merge_request.approval_state).to receive(:suggested_approvers).with(current_user: user) { [:ok] }

      is_expected.to contain_exactly(:ok)
    end
  end

  describe 'create vulnerability feedback paths' do
    where(:create_feedback_path) do
      [
        :create_vulnerability_feedback_issue_path,
        :create_vulnerability_feedback_merge_request_path,
        :create_vulnerability_feedback_dismissal_path
      ]
    end

    with_them do
      subject { described_class.new(merge_request, current_user: user).public_send(create_feedback_path, merge_request.project) }

      it { is_expected.to eq("/#{merge_request.project.full_path}/-/vulnerability_feedback") }

      context 'when not allowed to create vulnerability feedback' do
        let(:unauthorized_user) { create(:user) }

        subject { described_class.new(merge_request, current_user: unauthorized_user).public_send(create_feedback_path, merge_request.project) }

        it "does not contain #{params['create_feedback_path']}" do
          expect(subject).to be_nil
        end
      end
    end
  end

  describe '#approvals_widget_type' do
    subject { described_class.new(merge_request, current_user: user).approvals_widget_type }

    context 'when approvals feature is available for a project' do
      let(:approval_feature_available) { true }

      it 'returns full' do
        is_expected.to eq('full')
      end
    end

    context 'when approvals feature is not available for a project' do
      let(:approval_feature_available) { false }

      it 'returns base' do
        is_expected.to eq('base')
      end
    end
  end

  describe '#missing_security_scan_types' do
    let(:presenter) { described_class.new(merge_request, current_user: user) }
    let(:pipeline) { instance_double(Ci::Pipeline) }

    subject(:missing_security_scan_types) { presenter.missing_security_scan_types }

    before do
      stub_feature_flags(missing_mr_security_scan_types: feature_enabled?)
      allow(merge_request).to receive(:actual_head_pipeline).and_return(pipeline)
      allow(presenter).to receive(:can?).with(user, :read_pipeline, pipeline).and_return(can_read_pipeline?)
    end

    context 'when the `missing_mr_security_scan_types` feature flag is not enabled' do
      let(:feature_enabled?) { false }

      context 'when the `current_user` can not read the pipeline' do
        let(:can_read_pipeline?) { false }

        it { is_expected.to be_nil }
      end

      context 'when the `current_user` can read the pipeline' do
        let(:can_read_pipeline?) { true }

        it { is_expected.to be_nil }
      end
    end

    context 'when the `missing_mr_security_scan_types` feature flag is enabled' do
      let(:feature_enabled?) { true }

      context 'when the `current_user` can not read the pipeline' do
        let(:can_read_pipeline?) { false }

        it { is_expected.to be_nil }
      end

      context 'when the `current_user` can read the pipeline' do
        let(:can_read_pipeline?) { true }
        let(:missing_types) { %w(sast) }

        before do
          allow(merge_request).to receive(:missing_security_scan_types).and_return(missing_types)
        end

        it { is_expected.to eq(missing_types) }
      end
    end
  end
end
