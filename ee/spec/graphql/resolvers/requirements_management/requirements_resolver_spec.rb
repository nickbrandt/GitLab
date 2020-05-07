# frozen_string_literal: true

require 'spec_helper'

describe Resolvers::RequirementsManagement::RequirementsResolver do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }

  context 'with a project' do
    let_it_be(:project) { create(:project) }
    let_it_be(:requirement1) { create(:requirement, project: project, state: :opened, created_at: 5.hours.ago) }
    let_it_be(:requirement2) { create(:requirement, project: project, state: :archived, created_at: 3.hours.ago) }
    let_it_be(:requirement3) { create(:requirement, project: project, state: :archived, created_at: 4.hours.ago) }

    before do
      project.add_developer(current_user)
      stub_licensed_features(requirements: true)
    end

    describe '#resolve' do
      it 'finds all requirements' do
        expect(resolve_requirements).to contain_exactly(requirement1, requirement2, requirement3)
      end

      it 'filters by state' do
        expect(resolve_requirements(state: 'opened')).to contain_exactly(requirement1)
        expect(resolve_requirements(state: 'archived')).to contain_exactly(requirement2, requirement3)
      end

      it 'filters by iid' do
        expect(resolve_requirements(iid: requirement1.iid)).to contain_exactly(requirement1)
      end

      it 'filters by iids' do
        expect(resolve_requirements(iids: [requirement1.iid, requirement3.iid])).to contain_exactly(requirement1, requirement3)
      end

      describe 'sorting' do
        context 'when sorting by created_at' do
          it 'sorts requirements ascending' do
            expect(resolve_requirements(sort: 'created_asc')).to eq([requirement1, requirement3, requirement2])
          end

          it 'sorts requirements descending' do
            expect(resolve_requirements(sort: 'created_desc')).to eq([requirement2, requirement3, requirement1])
          end
        end
      end

      it 'finds only the requirements within the project we are looking at' do
        another_project = create(:project, :public)
        create(:requirement, project: another_project, iid: requirement1.iid)

        expect(resolve_requirements).to contain_exactly(requirement1, requirement2, requirement3)
      end
    end

    context 'when `requirements_management` flag is disabled' do
      before do
        stub_feature_flags(requirements_management: false)
      end

      it 'returns an empty list' do
        expect(resolve_requirements).to be_empty
      end
    end
  end

  def resolve_requirements(args = {}, context = { current_user: current_user })
    resolve(described_class, obj: project, args: args, ctx: context)
  end
end
