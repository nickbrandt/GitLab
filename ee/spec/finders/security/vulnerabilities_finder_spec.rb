# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::VulnerabilitiesFinder do
  let_it_be(:project) { create(:project) }

  let_it_be(:vulnerability1) do
    create(:vulnerability, severity: :low, report_type: :sast, state: :detected, project: project)
  end

  let_it_be(:vulnerability2) do
    create(:vulnerability, severity: :medium, report_type: :dast, state: :dismissed, project: project)
  end

  let_it_be(:vulnerability3) do
    create(:vulnerability, severity: :high, report_type: :dependency_scanning, state: :confirmed, project: project)
  end

  let(:filters) { {} }
  let(:vulnerable) { project }

  subject { described_class.new(vulnerable, filters).execute }

  it 'returns vulnerabilities of a project' do
    expect(subject).to match_array(project.vulnerabilities)
  end

  context 'when not given a second argument' do
    subject { described_class.new(project).execute }

    it 'does not filter the vulnerability list' do
      expect(subject).to match_array(project.vulnerabilities)
    end
  end

  context 'when filtered by report type' do
    let(:filters) { { report_type: %w[sast dast] } }

    it 'only returns vulnerabilities matching the given report types' do
      is_expected.to contain_exactly(vulnerability1, vulnerability2)
    end
  end

  context 'when filtered by severity' do
    let(:filters) { { severity: %w[medium high] } }

    it 'only returns vulnerabilities matching the given severities' do
      is_expected.to contain_exactly(vulnerability2, vulnerability3)
    end
  end

  context 'when filtered by state' do
    let(:filters) { { state: %w[detected confirmed] } }

    it 'only returns vulnerabilities matching the given states' do
      is_expected.to contain_exactly(vulnerability1, vulnerability3)
    end
  end

  context 'when filtered by project' do
    let(:group) { create(:group) }
    let(:another_project) { create(:project, namespace: group) }
    let!(:another_vulnerability) { create(:vulnerability, project: another_project) }
    let(:filters) { { project_id: [another_project.id] } }
    let(:vulnerable) { group }

    before do
      project.update(namespace: group)
    end

    it 'only returns vulnerabilities matching the given projects' do
      is_expected.to contain_exactly(another_vulnerability)
    end
  end

  context 'when filtered by more than one property' do
    let_it_be(:vulnerability4) do
      create(:vulnerability, severity: :medium, report_type: :sast, state: :detected, project: project)
    end

    let(:filters) { { report_type: %w[sast], severity: %w[medium] } }

    it 'only returns vulnerabilities matching all of the given filters' do
      is_expected.to contain_exactly(vulnerability4)
    end
  end
end
