# frozen_string_literal: true

require 'spec_helper'

describe Vulnerabilities::Occurrence do
  it { is_expected.to define_enum_for(:report_type) }

  describe 'associations' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:primary_identifier).class_name('Vulnerabilities::Identifier') }
    it { is_expected.to belong_to(:scanner).class_name('Vulnerabilities::Scanner') }
    it { is_expected.to have_many(:pipelines).class_name('Ci::Pipeline') }
    it { is_expected.to have_many(:occurrence_pipelines).class_name('Vulnerabilities::OccurrencePipeline') }
    it { is_expected.to have_many(:identifiers).class_name('Vulnerabilities::Identifier') }
    it { is_expected.to have_many(:occurrence_identifiers).class_name('Vulnerabilities::OccurrenceIdentifier') }
  end

  describe 'validations' do
    let(:occurrence) { build(:vulnerabilities_occurrence) }

    it { is_expected.to validate_presence_of(:scanner) }
    it { is_expected.to validate_presence_of(:project) }
    it { is_expected.to validate_presence_of(:uuid) }
    it { is_expected.to validate_presence_of(:project_fingerprint) }
    it { is_expected.to validate_presence_of(:primary_identifier) }
    it { is_expected.to validate_presence_of(:location_fingerprint) }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:report_type) }
    it { is_expected.to validate_presence_of(:metadata_version) }
    it { is_expected.to validate_presence_of(:raw_metadata) }
    it { is_expected.to validate_presence_of(:severity) }
    it { is_expected.to validate_inclusion_of(:severity).in_array(described_class::LEVELS.keys) }
    it { is_expected.to validate_presence_of(:confidence) }
    it { is_expected.to validate_inclusion_of(:confidence).in_array(described_class::LEVELS.keys) }
  end

  context 'database uniqueness' do
    let(:occurrence) { create(:vulnerabilities_occurrence) }
    let(:new_occurrence) { occurrence.dup.tap { |o| o.uuid = SecureRandom.uuid } }

    it "when all index attributes are identical" do
      expect { new_occurrence.save! }.to raise_error(ActiveRecord::RecordNotUnique)
    end

    describe 'when some parameters are changed' do
      using RSpec::Parameterized::TableSyntax

      # we use block to delay object creations
      where(:key, :value_block) do
        :primary_identifier | -> { create(:vulnerabilities_identifier) }
        :scanner | -> { create(:vulnerabilities_scanner) }
        :project | -> { create(:project) }
      end

      with_them do
        it "is valid" do
          expect { new_occurrence.update!({ key => value_block.call }) }.not_to raise_error
        end
      end
    end
  end

  describe '.report_type' do
    let(:report_type) { :sast }

    subject { described_class.report_type(report_type) }

    context 'when occurrence has the corresponding report type' do
      let!(:occurrence) { create(:vulnerabilities_occurrence, report_type: report_type) }

      it 'selects the occurrence' do
        is_expected.to eq([occurrence])
      end
    end

    context 'when occurrence does not have security reports' do
      let!(:occurrence) { create(:vulnerabilities_occurrence, report_type: :dependency_scanning) }

      it 'does not select the occurrence' do
        is_expected.to be_empty
      end
    end
  end
end
