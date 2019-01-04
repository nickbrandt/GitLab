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

  describe '.count_by_day_and_severity' do
    let(:project) { create(:project) }
    let(:date_1) { Time.zone.parse('2018-11-10') }
    let(:date_2) { Time.zone.parse('2018-11-12') }

    before do
      travel_to(date_1) do
        pipeline = create(:ci_pipeline, :success, project: project)

        create_list(:vulnerabilities_occurrence, 2,
          pipelines: [pipeline], project: project, report_type: :sast, severity: :high)
      end

      travel_to(date_2) do
        pipeline = create(:ci_pipeline, :success, project: project)

        create_list(:vulnerabilities_occurrence, 2,
          pipelines: [pipeline], project: project, report_type: :dependency_scanning, severity: :low)

        create_list(:vulnerabilities_occurrence, 1,
          pipelines: [pipeline], project: project, report_type: :dast, severity: :medium)

        create_list(:vulnerabilities_occurrence, 1,
          pipelines: [pipeline], project: project, report_type: :dast, severity: :low)
      end
    end

    subject do
      travel_to(Time.zone.parse('2018-11-15')) do
        described_class.count_by_day_and_severity(3.days)
      end
    end

    it 'returns expected counts for occurrences within given period' do
      first, second = subject
      expect(first.day).to eq(date_2)
      expect(first.severity).to eq('low')
      expect(first.count).to eq(3)
      expect(second.day).to eq(date_2)
      expect(second.severity).to eq('medium')
      expect(second.count).to eq(1)
    end
  end

  describe '.by_report_types' do
    let!(:vulnerability_sast) { create(:vulnerabilities_occurrence, report_type: :sast) }
    let!(:vulnerability_dast) { create(:vulnerabilities_occurrence, report_type: :dast) }
    let!(:vulnerability_depscan) { create(:vulnerabilities_occurrence, report_type: :dependency_scanning) }

    subject { described_class.by_report_types(param) }

    context 'with one param' do
      let(:param) { 0 }

      it 'returns found record' do
        is_expected.to contain_exactly(vulnerability_sast)
      end
    end

    context 'with array of params' do
      let(:param) { [1, 3] }

      it 'returns found records' do
        is_expected.to contain_exactly(vulnerability_dast, vulnerability_depscan)
      end
    end

    context 'without found record' do
      let(:param) { 2 }

      it 'returns empty collection' do
        is_expected.to be_empty
      end
    end
  end

  describe '.by_projects' do
    let!(:vulnerability1) { create(:vulnerabilities_occurrence) }
    let!(:vulnerability2) { create(:vulnerabilities_occurrence) }

    subject { described_class.by_projects(param) }

    context 'with found record' do
      let(:param) { vulnerability1.project_id }

      it 'returns found record' do
        is_expected.to contain_exactly(vulnerability1)
      end
    end
  end

  describe '.by_severities' do
    let!(:vulnerability_high) { create(:vulnerabilities_occurrence, severity: :high) }
    let!(:vulnerability_low) { create(:vulnerabilities_occurrence, severity: :low) }

    subject { described_class.by_severities(param) }

    context 'with one param' do
      let(:param) { 4 }

      it 'returns found record' do
        is_expected.to contain_exactly(vulnerability_low)
      end
    end

    context 'without found record' do
      let(:param) { 7 }

      it 'returns empty collection' do
        is_expected.to be_empty
      end
    end
  end

  describe '.count_by_severity' do
    let!(:high_vulnerabilities) { create_list(:vulnerabilities_occurrence, 3, severity: :high) }
    let!(:medium_vulnerabilities) { create_list(:vulnerabilities_occurrence, 2, severity: :medium) }
    let!(:low_vulnerabilities) { create_list(:vulnerabilities_occurrence, 1, severity: :low) }

    subject { described_class.counted_by_severity }

    it 'returns counts' do
      is_expected.to eq({ 4 => 1, 5 => 2, 6 => 3 })
    end
  end
end
