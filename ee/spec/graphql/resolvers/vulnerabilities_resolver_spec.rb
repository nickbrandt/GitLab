# frozen_string_literal: true

require 'spec_helper'

describe Resolvers::VulnerabilitiesResolver do
  include GraphqlHelpers

  describe '#resolve' do
    let_it_be(:project) { create(:project) }

    let_it_be(:low_vulnerability) do
      create(:vulnerability, :detected, :low, project: project, report_type: :dast)
    end

    let_it_be(:critical_vulnerability) do
      create(:vulnerability, :detected, :critical, project: project, report_type: :sast)
    end

    let_it_be(:high_vulnerability) do
      create(:vulnerability, :dismissed, :high, project: project, report_type: :container_scanning)
    end

    let(:filters) { {} }
    let(:vulnerable) { project }

    subject { resolve(described_class, obj: vulnerable, args: filters) }

    it "returns the project's vulnerabilities" do
      is_expected.to contain_exactly(critical_vulnerability, high_vulnerability, low_vulnerability)
    end

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
  end
end
