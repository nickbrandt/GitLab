# frozen_string_literal: true

require 'spec_helper'

describe Vulnerabilities::LetterGrade do
  let_it_be(:group) { create(:group) }
  let_it_be(:project_1) { create(:project, group: group) }
  let_it_be(:project_2) { create(:project, group: group) }
  let_it_be(:project_3) { create(:project, group: group) }
  let_it_be(:project_4) { create(:project, group: group) }
  let_it_be(:project_5) { create(:project, group: group) }
  let_it_be(:project_6) { create(:project, group: group) }

  before do
    create(:vulnerability, :critical, project: project_1)
    create(:vulnerability, :high, project: project_1)
    create(:vulnerability, :medium, project: project_2)
    create(:vulnerability, :low, project: project_3)
    create(:vulnerability, :low, project: project_4)
    create(:vulnerability, :critical, :resolved, project: project_5)
    create(:vulnerability, :unknown, project: project_6)
  end

  describe '.for' do
    subject(:letter_grades) { described_class.for(vulnerable) }

    context 'when the given object does not respond to projects' do
      let(:vulnerable) { :foo }
      let(:error_message) { ':foo does not respond_to `projects`' }

      it 'raises a meaningful error rather than a NoMethodError' do
        expect { letter_grades }.to raise_error(RuntimeError, error_message)
      end
    end

    context 'when the given vulnerable is a Group' do
      let(:vulnerable) { group }
      let(:expected_letter_grades) do
        [
          described_class.new(vulnerable, 'a', 1),
          described_class.new(vulnerable, 'b', 2),
          described_class.new(vulnerable, 'c', 1),
          described_class.new(vulnerable, 'd', 1),
          described_class.new(vulnerable, 'f', 1)
        ]
      end

      it 'returns the letter grades for given vulnerable' do
        expect(letter_grades).to match_array(expected_letter_grades)
      end
    end

    context 'when the given vulnerable is an InstanceSecurityDashboard' do
      let(:user) { create(:user) }
      let(:vulnerable) { InstanceSecurityDashboard.new(user) }
      let(:expected_letter_grades) do
        [
          described_class.new(vulnerable, 'a', 0),
          described_class.new(vulnerable, 'b', 0),
          described_class.new(vulnerable, 'c', 0),
          described_class.new(vulnerable, 'd', 0),
          described_class.new(vulnerable, 'f', 1)
        ]
      end

      before do
        project_1.add_developer(user)
        user.security_dashboard_projects << project_1
      end

      it 'returns the letter grades for given vulnerable' do
        expect(letter_grades).to match_array(expected_letter_grades)
      end
    end
  end

  describe '#projects' do
    let(:letter_grade) { described_class.new(group, 'b', 2) }
    let(:expected_projects) { [project_3, project_4] }

    subject(:projects) { letter_grade.projects }

    it { is_expected.to match_array(expected_projects) }
  end
end
