# frozen_string_literal: true

require 'spec_helper'

describe Vulnerabilities::FeedbackEntity do
  set(:user) { create(:user) }
  set(:project) { create(:project) }
  let(:request) { double('request') }
  let(:entity) { described_class.represent(feedback, request: request) }

  subject { entity.as_json }

  before do
    allow(request).to receive(:current_user).and_return(user)
  end

  describe '#as_json' do
    let(:feedback) { build(:vulnerability_feedback, :issue, project: project) }

    it { is_expected.to include(:created_at, :project_id, :author, :category, :feedback_type) }

    context 'feedback type is issue' do
      let(:feedback) { build(:vulnerability_feedback, :issue, project: project) }

      it 'exposes issue information' do
        is_expected.to include(:issue_iid)
        is_expected.to include(:issue_url)
      end

      context 'when issue is not present' do
        let(:feedback) { build(:vulnerability_feedback, feedback_type: :issue, project: project, issue: nil) }

        it 'does not expose issue information' do
          is_expected.not_to include(:issue_iid)
          is_expected.not_to include(:issue_url)
        end
      end

      context 'when allowed to destroy vulnerability feedback' do
        before do
          project.add_developer(user)
        end

        it 'does not contain destroy vulnerability feedback dismissal path' do
          expect(subject).not_to include(:destroy_vulnerability_feedback_dismissal_path)
        end
      end
    end

    context 'feedback type is merge_request' do
      let(:feedback) { build(:vulnerability_feedback, :merge_request, project: project) }

      it 'exposes merge request information' do
        is_expected.to include(:merge_request_iid)
        is_expected.to include(:merge_request_path)
      end

      context 'when merge request is not present' do
        let(:feedback) { build(:vulnerability_feedback, :merge_request, project: project, merge_request: nil) }

        it 'does not expose merge request information' do
          is_expected.not_to include(:merge_request_iid)
          is_expected.not_to include(:merge_request_path)
        end
      end

      context 'when allowed to destroy vulnerability feedback' do
        before do
          project.add_developer(user)
        end

        it 'does not contain destroy vulnerability feedback dismissal path' do
          expect(subject).not_to include(:destroy_vulnerability_feedback_dismissal_path)
        end
      end
    end

    context 'feedback type is dismissal' do
      let(:feedback) { create(:vulnerability_feedback, :dismissal, project: project) }

      context 'when not allowed to destroy vulnerability feedback' do
        before do
          project.add_guest(user)
        end

        it 'does not contain destroy vulnerability feedback dismissal path' do
          expect(subject).not_to include(:destroy_vulnerability_feedback_dismissal_path)
        end
      end

      context 'when allowed to destroy vulnerability feedback' do
        before do
          project.add_developer(user)
        end

        it 'contains destroy vulnerability feedback dismissal path' do
          expect(subject).to include(:destroy_vulnerability_feedback_dismissal_path)
        end
      end
    end
  end

  context 'when comment is not present' do
    let(:feedback) { build(:vulnerability_feedback, :dismissal) }

    it { is_expected.not_to include(:comment_details) }
  end

  context 'when comment is present' do
    let(:feedback) { build(:vulnerability_feedback, :comment) }

    it 'exposes comment information' do
      expect(subject).to include(:comment_details)
      expect(subject[:comment_details]).to include(:comment)
      expect(subject[:comment_details]).to include(:comment_timestamp)
      expect(subject[:comment_details]).to include(:comment_author)
    end
  end

  context 'when issue is present' do
    let(:feedback) { build(:vulnerability_feedback, :issue ) }

    it 'exposes issue information' do
      is_expected.to include(:issue_iid)
      is_expected.to include(:issue_url)
    end
  end

  context 'when issue is not present' do
    let(:feedback) { build(:vulnerability_feedback, feedback_type: 'issue', issue: nil) }

    it 'does not expose issue information' do
      is_expected.not_to include(:issue_iid)
      is_expected.not_to include(:issue_url)
    end
  end

  context 'when merge request is present' do
    let(:feedback) { build(:vulnerability_feedback, :merge_request ) }

    it 'exposes merge request information' do
      is_expected.to include(:merge_request_iid)
      is_expected.to include(:merge_request_path)
    end
  end

  context 'when merge request is not present' do
    let(:feedback) { build(:vulnerability_feedback, feedback_type: 'merge_request', merge_request: nil) }

    it 'does not expose merge request information' do
      is_expected.not_to include(:merge_request_iid)
      is_expected.not_to include(:merge_request_path)
    end
  end
end
