# frozen_string_literal: true

require 'spec_helper'

describe Vulnerabilities::FeedbackEntity do
  let(:feedback) { build(:vulnerability_feedback) }

  let(:entity) { described_class.represent(feedback) }

  describe '#as_json' do
    subject { entity.as_json }

    it { is_expected.to include(:project_id, :author, :category, :feedback_type) }
  end

  context 'when issue is present' do
    let(:feedback) { build(:vulnerability_feedback, :issue ) }
    let(:entity) { described_class.represent(feedback) }

    subject { entity.as_json }

    it 'exposes issue information' do
      is_expected.to include(:issue_iid)
      is_expected.to include(:issue_url)
    end
  end

  context 'when issue is not present' do
    let(:feedback) { build(:vulnerability_feedback, feedback_type: 'issue', issue: nil) }
    let(:entity) { described_class.represent(feedback) }

    subject { entity.as_json }

    it 'does not expose issue information' do
      is_expected.not_to include(:issue_iid)
      is_expected.not_to include(:issue_url)
    end
  end

  context 'when merge request is present' do
    let(:feedback) { build(:vulnerability_feedback, :merge_request ) }
    let(:entity) { described_class.represent(feedback) }

    subject { entity.as_json }

    it 'exposes merge request information' do
      is_expected.to include(:merge_request_iid)
      is_expected.to include(:merge_request_path)
    end
  end

  context 'when merge request is not present' do
    let(:feedback) { build(:vulnerability_feedback, feedback_type: 'merge_request', merge_request: nil) }
    let(:entity) { described_class.represent(feedback) }

    subject { entity.as_json }

    it 'does not expose merge request information' do
      is_expected.not_to include(:merge_request_iid)
      is_expected.not_to include(:merge_request_path)
    end
  end
end
