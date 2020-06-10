# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::VulnerableProjectsFinder do
  describe '#execute' do
    let(:projects) { Project.all }
    let!(:safe_project) { create(:project) }
    let(:vulnerable_project) { create(:project) }
    let!(:vulnerability) { create(:vulnerabilities_occurrence, project: vulnerable_project) }

    subject { described_class.new(projects).execute }

    it 'returns the projects that have vulnerabilities from the collection of projects given to it' do
      expect(subject).to contain_exactly(vulnerable_project)
    end

    it 'does not include projects that only have dismissed vulnerabilities' do
      create(:vulnerabilities_occurrence, :dismissed, project: safe_project)

      expect(subject).to contain_exactly(vulnerable_project)
    end

    it 'only uses 1 query' do
      another_project = create(:project)
      create(:vulnerabilities_occurrence, :dismissed, project: another_project)

      expect { subject }.not_to exceed_query_limit(1)

      expect(subject).to contain_exactly(vulnerable_project)
    end
  end
end
