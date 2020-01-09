# frozen_string_literal: true

require 'spec_helper'

shared_examples_for Vulnerable do
  include VulnerableHelpers

  let(:external_project) { as_external_vulnerable_project(vulnerable) }
  let(:failed_pipeline) { create(:ci_pipeline, :failed, project: vulnerable_project) }

  let!(:old_vuln) { create_vulnerability(vulnerable_project) }
  let!(:new_vuln) { create_vulnerability(vulnerable_project) }
  let!(:external_vuln) { create_vulnerability(external_project) }
  let!(:failed_vuln) { create_vulnerability(vulnerable_project, failed_pipeline) }
  let(:vulnerable_project) { as_vulnerable_project(vulnerable) }

  before do
    pipeline_ran_against_new_sha = create(:ci_pipeline, :success, project: vulnerable_project, sha: '123')
    new_vuln.pipelines << pipeline_ran_against_new_sha
  end

  def create_vulnerability(project, pipeline = nil)
    if project
      pipeline ||= create(:ci_pipeline, :success, project: project)
      create(:vulnerabilities_occurrence, pipelines: [pipeline], project: project)
    end
  end

  describe '#latest_vulnerabilities' do
    subject { vulnerable.latest_vulnerabilities }

    it 'returns vulnerabilities for the latest successful pipelines of projects belonging to the vulnerable entity' do
      is_expected.to contain_exactly(new_vuln)
    end

    context 'with vulnerabilities from other branches' do
      let!(:branch_pipeline) { create(:ci_pipeline, :success, project: vulnerable_project, ref: 'feature-x') }
      let!(:branch_vuln) { create(:vulnerabilities_occurrence, pipelines: [branch_pipeline], project: vulnerable_project) }

      # TODO: This should actually fail and we must scope vulns
      # per branch as soon as we store them for other branches
      # Dependent on https://gitlab.com/gitlab-org/gitlab/issues/9524
      it 'includes vulnerabilities from all branches' do
        is_expected.to contain_exactly(branch_vuln)
      end
    end
  end

  describe '#latest_vulnerabilities_with_sha' do
    subject { vulnerable.latest_vulnerabilities_with_sha }

    it 'returns vulns only for the latest successful pipelines of projects belonging to the vulnerable' do
      is_expected.to contain_exactly(new_vuln)
    end

    it { is_expected.to all(respond_to(:sha)) }

    context 'with vulnerabilities from other branches' do
      let!(:branch_pipeline) { create(:ci_pipeline, :success, project: vulnerable_project, ref: 'feature-x') }
      let!(:branch_vuln) { create(:vulnerabilities_occurrence, pipelines: [branch_pipeline], project: vulnerable_project) }

      # TODO: This should actually fail and we must scope vulns
      # per branch as soon as we store them for other branches
      # Dependent on https://gitlab.com/gitlab-org/gitlab/issues/9524
      it 'includes vulnerabilities from all branches' do
        is_expected.to contain_exactly(branch_vuln)
      end
    end
  end

  describe '#all_vulnerabilities' do
    subject { vulnerable.all_vulnerabilities }

    it 'returns vulns for all successful pipelines of projects belonging to the vulnerable' do
      is_expected.to contain_exactly(old_vuln, new_vuln, new_vuln)
    end

    context 'with vulnerabilities from other branches' do
      let!(:branch_pipeline) { create(:ci_pipeline, :success, project: vulnerable_project, ref: 'feature-x') }
      let!(:branch_vuln) { create(:vulnerabilities_occurrence, pipelines: [branch_pipeline], project: vulnerable_project) }

      # TODO: This should actually fail and we must scope vulns
      # per branch as soon as we store them for other branches
      # Dependent on https://gitlab.com/gitlab-org/gitlab/issues/9524
      it 'includes vulnerabilities from all branches' do
        is_expected.to contain_exactly(old_vuln, new_vuln, new_vuln, branch_vuln)
      end
    end
  end
end
