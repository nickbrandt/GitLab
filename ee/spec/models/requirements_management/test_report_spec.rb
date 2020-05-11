# frozen_string_literal: true

require 'spec_helper'

describe RequirementsManagement::TestReport do
  describe 'associations' do
    subject { build(:test_report) }

    it { is_expected.to belong_to(:author).class_name('User') }
    it { is_expected.to belong_to(:requirement) }
    it { is_expected.to belong_to(:pipeline) }
  end

  describe 'validations' do
    subject { build(:test_report) }

    it { is_expected.to validate_presence_of(:requirement) }
    it { is_expected.to validate_presence_of(:state) }
  end
end
