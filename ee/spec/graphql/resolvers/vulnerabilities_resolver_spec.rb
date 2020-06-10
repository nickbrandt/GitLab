# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::VulnerabilitiesResolver do
  include GraphqlHelpers

  describe '#resolve' do
    subject { resolve(described_class, obj: vulnerable, args: filters, ctx: { current_user: current_user }) }

    let_it_be(:project) { create(:project) }
    let_it_be(:user) { create(:user, security_dashboard_projects: [project]) }

    let_it_be(:low_vulnerability) do
      create(:vulnerability, :detected, :low, :dast, project: project)
    end

    let_it_be(:critical_vulnerability) do
      create(:vulnerability, :detected, :critical, :sast, project: project)
    end

    let_it_be(:high_vulnerability) do
      create(:vulnerability, :dismissed, :high, :container_scanning, project: project)
    end

    let(:current_user) { user }
    let(:filters) { {} }
    let(:vulnerable) { project }

    it 'orders results by severity' do
      expect(subject.first).to eq(critical_vulnerability)
      expect(subject.second).to eq(high_vulnerability)
      expect(subject.third).to eq(low_vulnerability)
    end

    context 'when given severities' do
      let(:filters) { { severity: ['low'] } }

      it 'only returns vulnerabilities of the given severities' do
        is_expected.to contain_exactly(low_vulnerability)
      end
    end

    context 'when given states' do
      let(:filters) { { state: ['dismissed'] } }

      it 'only returns vulnerabilities of the given states' do
        is_expected.to contain_exactly(high_vulnerability)
      end
    end

    context 'when given report types' do
      let(:filters) { { report_type: %i[dast sast] } }

      it 'only returns vulnerabilities of the given report types' do
        is_expected.to contain_exactly(critical_vulnerability, low_vulnerability)
      end
    end

    context 'when given project IDs' do
      let_it_be(:group) { create(:group) }
      let_it_be(:project2) { create(:project, namespace: group) }
      let_it_be(:project2_vulnerability) { create(:vulnerability, project: project2) }

      let(:filters) { { project_id: [project2.id] } }
      let(:vulnerable) { group }

      before do
        project.update(namespace: group)
      end

      it 'only returns vulnerabilities belonging to the given projects' do
        is_expected.to contain_exactly(project2_vulnerability)
      end
    end

    context 'when resolving vulnerabilities for a project' do
      it "returns the project's vulnerabilities" do
        is_expected.to contain_exactly(critical_vulnerability, high_vulnerability, low_vulnerability)
      end
    end

    context 'when resolving vulnerabilities for an instance security dashboard' do
      before do
        project.add_developer(user)
      end

      let(:vulnerable) { nil }

      context 'when there is a current user' do
        it "returns vulnerabilities for all projects on the current user's instance security dashboard" do
          is_expected.to contain_exactly(critical_vulnerability, high_vulnerability, low_vulnerability)
        end
      end

      context 'and there is no current user' do
        let(:current_user) { nil }

        it 'returns no vulnerabilities' do
          is_expected.to be_empty
        end
      end
    end
  end
end
