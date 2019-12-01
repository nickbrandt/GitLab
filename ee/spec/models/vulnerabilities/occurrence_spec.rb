# frozen_string_literal: true

require 'spec_helper'

describe Vulnerabilities::Occurrence do
  it { is_expected.to define_enum_for(:confidence) }
  it { is_expected.to define_enum_for(:report_type) }
  it { is_expected.to define_enum_for(:severity) }

  describe 'associations' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:primary_identifier).class_name('Vulnerabilities::Identifier') }
    it { is_expected.to belong_to(:scanner).class_name('Vulnerabilities::Scanner') }
    it { is_expected.to belong_to(:vulnerability).inverse_of(:findings) }
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
    it { is_expected.to validate_presence_of(:confidence) }
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
      where(:key, :factory_name) do
        :primary_identifier | :vulnerabilities_identifier
        :scanner | :vulnerabilities_scanner
        :project | :project
      end

      with_them do
        it "is valid" do
          expect { new_occurrence.update!({ key => create(factory_name) }) }.not_to raise_error
        end
      end
    end
  end

  context 'order' do
    let!(:occurrence1) { create(:vulnerabilities_occurrence, confidence: described_class::CONFIDENCE_LEVELS[:high], severity:   described_class::SEVERITY_LEVELS[:high]) }
    let!(:occurrence2) { create(:vulnerabilities_occurrence, confidence: described_class::CONFIDENCE_LEVELS[:medium], severity: described_class::SEVERITY_LEVELS[:critical]) }
    let!(:occurrence3) { create(:vulnerabilities_occurrence, confidence: described_class::CONFIDENCE_LEVELS[:high], severity:   described_class::SEVERITY_LEVELS[:critical]) }

    it 'orders by severity and confidence' do
      expect(described_class.all.ordered).to eq([occurrence3, occurrence2, occurrence1])
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

  describe '.for_pipelines_with_sha' do
    let(:project) { create(:project) }
    let(:pipeline) { create(:ci_pipeline, :success, project: project) }

    before do
      create(:vulnerabilities_occurrence, pipelines: [pipeline], project: project)
    end

    subject(:occurrences) { described_class.for_pipelines_with_sha([pipeline]) }

    it 'sets the sha' do
      expect(occurrences.first.sha).to eq(pipeline.sha)
    end
  end

  describe '.count_by_day_and_severity' do
    let(:project) { create(:project) }
    let(:date_1) { Time.zone.parse('2018-11-11') }
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
        described_class.count_by_day_and_severity(range)
      end
    end

    context 'within 3-day period' do
      let(:range) { 3.days }

      it 'returns expected counts for occurrences' do
        first, second = subject

        expect(first.day).to eq(date_2)
        expect(first.severity).to eq('low')
        expect(first.count).to eq(3)
        expect(second.day).to eq(date_2)
        expect(second.severity).to eq('medium')
        expect(second.count).to eq(1)
      end
    end

    context 'within 4-day period' do
      let(:range) { 4.days }

      it 'returns expected counts for occurrences' do
        first, second, third = subject

        expect(first.day).to eq(date_1)
        expect(first.severity).to eq('high')
        expect(first.count).to eq(2)
        expect(second.day).to eq(date_2)
        expect(second.severity).to eq('low')
        expect(second.count).to eq(3)
        expect(third.day).to eq(date_2)
        expect(third.severity).to eq('medium')
        expect(third.count).to eq(1)
      end
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
      let(:param) { described_class.severities[:low] }

      it 'returns found record' do
        is_expected.to contain_exactly(vulnerability_low)
      end
    end

    context 'without found record' do
      let(:param) { described_class.severities[:unknown] }

      it 'returns empty collection' do
        is_expected.to be_empty
      end
    end
  end

  describe '.by_confidences' do
    let!(:vulnerability_high) { create(:vulnerabilities_occurrence, confidence: :high) }
    let!(:vulnerability_low) { create(:vulnerabilities_occurrence, confidence: :low) }

    subject { described_class.by_confidences(param) }

    context 'with matching param' do
      let(:param) { described_class.confidences[:low] }

      it 'returns found record' do
        is_expected.to contain_exactly(vulnerability_low)
      end
    end

    context 'with non-matching param' do
      let(:param) { described_class.confidences[:unknown] }

      it 'returns empty collection' do
        is_expected.to be_empty
      end
    end
  end

  describe '.counted_by_severity' do
    let!(:high_vulnerabilities) { create_list(:vulnerabilities_occurrence, 3, severity: :high) }
    let!(:medium_vulnerabilities) { create_list(:vulnerabilities_occurrence, 2, severity: :medium) }
    let!(:low_vulnerabilities) { create_list(:vulnerabilities_occurrence, 1, severity: :low) }

    subject { described_class.counted_by_severity }

    it 'returns counts' do
      is_expected.to eq({ 4 => 1, 5 => 2, 6 => 3 })
    end
  end

  describe '.undismissed' do
    set(:project) { create(:project) }
    set(:project2) { create(:project) }
    let!(:finding1) { create(:vulnerabilities_occurrence, project: project) }
    let!(:finding2) { create(:vulnerabilities_occurrence, project: project) }
    let!(:finding3) { create(:vulnerabilities_occurrence, project: project2) }

    before do
      create(
        :vulnerability_feedback,
        :dismissal,
        project_fingerprint: finding1.project_fingerprint
      )
    end

    it 'returns all non-dismissed occurrences' do
      expect(described_class.undismissed).to contain_exactly(finding2, finding3)
    end

    it 'returns non-dismissed occurrences for project' do
      expect(project2.vulnerability_findings.undismissed).to contain_exactly(finding3)
    end
  end

  describe '.batch_count_by_project_and_severity' do
    let(:project) { create(:project) }

    it 'fetches a vulnerability count for the given project and severity' do
      create(:vulnerabilities_occurrence, project: project, severity: :high)

      count = described_class.batch_count_by_project_and_severity(project.id, 'high')

      expect(count).to be(1)
    end

    it 'returns 0 when there are no vulnerabilities for that severity level' do
      count = described_class.batch_count_by_project_and_severity(project.id, 'high')

      expect(count).to be(0)
    end

    it 'batch loads the counts' do
      projects = create_list(:project, 2)

      projects.each do |project|
        create(:vulnerabilities_occurrence, project: project, severity: :high)
        create(:vulnerabilities_occurrence, project: project, severity: :low)
      end

      projects_and_severities = [
        [projects.first, 'high'],
        [projects.first, 'low'],
        [projects.second, 'high'],
        [projects.second, 'low']
      ]

      counts = projects_and_severities.map do |(project, severity)|
        described_class.batch_count_by_project_and_severity(project.id, severity)
      end

      expect { expect(counts).to all(be 1) }.not_to exceed_query_limit(1)
    end

    it 'does not include dismissed vulnerabilities in the counts' do
      create(:vulnerabilities_occurrence, project: project, severity: :high)
      dismissed_vulnerability = create(:vulnerabilities_occurrence, project: project, severity: :high)
      create(
        :vulnerability_feedback,
        project: project,
        project_fingerprint: dismissed_vulnerability.project_fingerprint,
        feedback_type: :dismissal
      )

      count = described_class.batch_count_by_project_and_severity(project.id, 'high')

      expect(count).to be(1)
    end
  end

  describe 'feedback' do
    set(:project) { create(:project) }
    let(:occurrence) do
      create(
        :vulnerabilities_occurrence,
        report_type: :dependency_scanning,
        project: project
      )
    end

    describe '#issue_feedback' do
      let(:issue) { create(:issue, project: project) }
      let!(:issue_feedback) do
        create(
          :vulnerability_feedback,
          :dependency_scanning,
          :issue,
          issue: issue,
          project: project,
          project_fingerprint: occurrence.project_fingerprint
        )
      end

      it 'returns associated feedback' do
        feedback = occurrence.issue_feedback

        expect(feedback).to be_present
        expect(feedback[:project_id]).to eq project.id
        expect(feedback[:feedback_type]).to eq 'issue'
        expect(feedback[:issue_id]).to eq issue.id
      end
    end

    describe '#dismissal_feedback' do
      let!(:dismissal_feedback) do
        create(
          :vulnerability_feedback,
          :dependency_scanning,
          :dismissal,
          project: project,
          project_fingerprint: occurrence.project_fingerprint
        )
      end

      it 'returns associated feedback' do
        feedback = occurrence.dismissal_feedback

        expect(feedback).to be_present
        expect(feedback[:project_id]).to eq project.id
        expect(feedback[:feedback_type]).to eq 'dismissal'
      end
    end

    describe '#merge_request_feedback' do
      let(:merge_request) { create(:merge_request, source_project: project) }
      let!(:merge_request_feedback) do
        create(
          :vulnerability_feedback,
          :dependency_scanning,
          :merge_request,
          merge_request: merge_request,
          project: project,
          project_fingerprint: occurrence.project_fingerprint
        )
      end

      it 'returns associated feedback' do
        feedback = occurrence.merge_request_feedback

        expect(feedback).to be_present
        expect(feedback[:project_id]).to eq project.id
        expect(feedback[:feedback_type]).to eq 'merge_request'
        expect(feedback[:merge_request_id]).to eq merge_request.id
      end
    end
  end

  describe '#state' do
    before do
      create(:vulnerability, :closed, project: finding_with_issue.project, findings: [finding_with_issue])
    end

    let(:unresolved_finding) { create(:vulnerabilities_finding) }
    let(:confirmed_finding) { create(:vulnerabilities_finding, :confirmed) }
    let(:resolved_finding) { create(:vulnerabilities_finding, :resolved) }
    let(:dismissed_finding) { create(:vulnerabilities_finding, :dismissed) }
    let(:finding_with_issue) { create(:vulnerabilities_finding, :with_issue_feedback) }

    it 'returns the expected state for a unresolved finding' do
      expect(unresolved_finding.state).to eq 'opened'
    end

    it 'returns the expected state for a confirmed finding' do
      expect(confirmed_finding.state).to eq 'confirmed'
    end

    it 'returns the expected state for a resolved finding' do
      expect(resolved_finding.state).to eq 'resolved'
    end

    it 'returns the expected state for a dismissed finding' do
      expect(dismissed_finding.state).to eq 'dismissed'
    end

    context 'when a vulnerability present for a dismissed finding' do
      before do
        create(:vulnerability, project: dismissed_finding.project, findings: [dismissed_finding])
      end

      it 'still reports a dismissed state' do
        expect(dismissed_finding.state).to eq 'dismissed'
      end
    end

    context 'when a non-dismissal feedback present for a finding belonging to a closed vulnerability' do
      before do
        create(:vulnerability_feedback, :issue, project: resolved_finding.project)
      end

      it 'reports as resolved' do
        expect(resolved_finding.state).to eq 'resolved'
      end
    end
  end
end
