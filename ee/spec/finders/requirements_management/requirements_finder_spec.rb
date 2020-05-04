# frozen_string_literal: true

require 'spec_helper'

describe RequirementsManagement::RequirementsFinder do
  let_it_be(:project) { create(:project) }
  let_it_be(:project_user) { create(:user).tap { |u| project.add_developer(u) } }
  let_it_be(:requirement1) { create(:requirement, project: project, state: 'opened', updated_at: 3.days.ago) }
  let_it_be(:requirement2) { create(:requirement, project: project, state: 'opened', updated_at: 1.day.ago) }
  let_it_be(:requirement3) { create(:requirement, project: project, state: 'archived', updated_at: 2.days.ago) }
  let_it_be(:requirement4) { create(:requirement, state: 'opened') }

  subject { described_class.new(project_user, params).execute }

  describe '#execute' do
    context 'when requirements are enabled' do
      before do
        stub_licensed_features(requirements: true)
      end

      context 'when project is not set' do
        let(:params) { {} }

        it 'does not return any requirements' do
          is_expected.to be_empty
        end
      end

      context 'when project is set' do
        let(:params) { { project_id: project.id } }

        it 'returns all requirements in the project' do
          is_expected.to match_array([requirement1, requirement2, requirement3])
        end
      end

      context 'when state is set' do
        let(:params) { { project_id: project.id, state: 'opened' } }

        it 'returns matched requirements' do
          is_expected.to match_array([requirement1, requirement2])
        end
      end

      context 'when iid is set' do
        let(:params) { { project_id: project.id, iids: [requirement2.iid, requirement3.iid] } }

        it 'returns matched requirements' do
          is_expected.to match_array([requirement2, requirement3])
        end
      end

      context 'when user can not read requirements in the project' do
        let(:user) { create(:user) }
        let(:params) { { project_id: project.id } }

        it 'does not return any requirements' do
          expect(described_class.new(user, params).execute).to be_empty
        end
      end

      describe 'ordering' do
        using RSpec::Parameterized::TableSyntax

        let(:params) { { project_id: project.id, sort: sort } }

        where(:sort, :ordered_requirements) do
          'id_asc'          | [:requirement1, :requirement2, :requirement3]
          'id_desc'         | [:requirement3, :requirement2, :requirement1]
          'updated_at_asc'  | [:requirement1, :requirement3, :requirement2]
          'updated_at_desc' | [:requirement2, :requirement3, :requirement1]
          'err'             | [:requirement3, :requirement2, :requirement1]
        end

        with_them do
          it 'returns the requirements ordered' do
            expect(subject).to eq(ordered_requirements.map { |name| public_send(name) })
          end
        end
      end
    end

    context 'when requirements are disabled' do
      before do
        stub_licensed_features(requirements: false)
      end

      context 'when project is set' do
        let(:params) { { project_id: project.id } }

        it 'does not return any requirements' do
          is_expected.to be_empty
        end
      end
    end
  end
end
