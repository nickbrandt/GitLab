# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DailyCodeCoverage do
  describe 'validation' do
    subject { described_class.new }

    it { is_expected.to validate_presence_of(:project_id) }
    it { is_expected.to validate_presence_of(:last_pipeline_id) }
    it { is_expected.to validate_presence_of(:ref) }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:coverage) }
    it { is_expected.to validate_presence_of(:date) }

    context 'uniqueness' do
      before do
        create(:daily_code_coverage)
      end

      it { is_expected.to validate_uniqueness_of(:project_id).scoped_to([:ref, :name, :date]) }
    end

    context 'ensuring newer pipeline' do
      context 'on new records' do
        subject { build(:daily_code_coverage, last_pipeline_id: 1) }

        it { is_expected.to be_valid }
      end

      context 'on existing records' do
        subject { create(:daily_code_coverage, last_pipeline_id: 12) }

        context 'and new pipeline ID is older' do
          before do
            subject.last_pipeline_id = 10
          end

          it { is_expected.not_to be_valid }
        end

        context 'and new pipeline ID is newer' do
          before do
            subject.last_pipeline_id = 15
          end

          it { is_expected.to be_valid }
        end
      end
    end
  end
end
