# frozen_string_literal: true

require 'spec_helper'

describe Vulnerabilities::FeedbackEntity do
  let(:feedback) { build(:vulnerability_feedback) }

  let(:entity) { described_class.represent(feedback) }

  describe '#as_json' do
    subject { entity.as_json }

    it { is_expected.to include(:project_id, :author, :category, :feedback_type) }
  end
end
