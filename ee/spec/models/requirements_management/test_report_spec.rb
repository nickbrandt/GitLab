# frozen_string_literal: true

require 'spec_helper'

describe RequirementsManagement::TestReport do
  describe 'associations' do
    subject { build(:test_report) }

    it { is_expected.to belong_to(:author).class_name('User') }
    it { is_expected.to belong_to(:requirement) }
    it { is_expected.to belong_to(:pipeline) }
    it { is_expected.to belong_to(:build) }
  end

  describe 'validations' do
    subject { build(:test_report) }

    it { is_expected.to validate_presence_of(:requirement) }
    it { is_expected.to validate_presence_of(:state) }

    describe 'pipeline reference' do
      it { is_expected.to be_valid }

      it 'is valid to if both build and pipeline are nil' do
        subject.build = nil
        subject.pipeline_id = nil

        expect(subject).to be_valid
      end

      it 'is invalid if build references a different pipeline' do
        subject.pipeline_id = nil

        expect(subject).to be_invalid
      end
    end
  end
end
