# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::RequirementsManagement::RequirementsResolver do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:other_user) { create(:user) }
  let_it_be(:third_user) { create(:user) }
  let_it_be(:project) { create(:project) }

  specify do
    expect(described_class).to have_nullable_graphql_type(::Types::RequirementsManagement::RequirementType.connection_type)
  end

  context 'with a project' do
    let_it_be(:requirement1) { create(:requirement, project: project, state: :opened, created_at: 5.hours.ago, title: 'it needs to do the thing', author: current_user) }
    let_it_be(:requirement2) { create(:requirement, project: project, state: :closed, created_at: 3.hours.ago, title: 'it needs to not break', author: other_user) }
    let_it_be(:requirement3) { create(:requirement, project: project, state: :closed, created_at: 4.hours.ago, title: 'do the kubernetes!', author: third_user) }

    before do
      project.add_developer(current_user)
      stub_licensed_features(requirements: true)
    end

    describe '#resolve' do
      it 'finds all requirements' do
        expect(resolve_requirements).to contain_exactly(requirement1, requirement2, requirement3)
      end

      context 'filter by state' do
        it 'filters by state' do
          expect(resolve_requirements(state: 'opened')).to contain_exactly(requirement1)
          expect(resolve_requirements(state: 'closed')).to contain_exactly(requirement2, requirement3)
        end

        # remove this in %14.6
        it 'accepts archived as an alias for closed' do
          expect(resolve_requirements(state: 'archived')).to contain_exactly(requirement2, requirement3)
        end
      end

      it 'filters by iid' do
        expect(resolve_requirements(iid: requirement1.iid)).to contain_exactly(requirement1)
      end

      it 'filters by iids' do
        expect(resolve_requirements(iids: [requirement1.iid, requirement3.iid])).to contain_exactly(requirement1, requirement3)
      end

      context 'when filtering by last test report state' do
        before do
          create(:test_report, state: :failed)
          create(:test_report, requirement: requirement1, state: :passed)
          create(:test_report, requirement: requirement1, state: :failed)
          create(:test_report, requirement: requirement3, state: :passed)
        end

        it 'filters by failed requirements' do
          expect(resolve_requirements(last_test_report_state: 'failed')).to contain_exactly(requirement1)
        end

        it 'filters by passed requirements' do
          expect(resolve_requirements(last_test_report_state: 'passed')).to contain_exactly(requirement3)
        end

        it 'filters requirements without test reports' do
          expect(resolve_requirements(last_test_report_state: 'missing')).to contain_exactly(requirement2)
        end
      end

      describe 'sorting' do
        context 'when sorting by created_at' do
          it 'sorts requirements ascending' do
            expect(resolve_requirements(sort: 'created_asc').to_a).to eq([requirement1, requirement3, requirement2])
          end

          it 'sorts requirements descending' do
            expect(resolve_requirements(sort: 'created_desc').to_a).to eq([requirement2, requirement3, requirement1])
          end
        end
      end

      it 'finds only the requirements within the project we are looking at' do
        another_project = create(:project, :public)
        create(:requirement, project: another_project, iid: requirement1.iid)

        expect(resolve_requirements).to contain_exactly(requirement1, requirement2, requirement3)
      end
    end

    context 'with search' do
      it 'filters requirements by title' do
        requirements = resolve_requirements(search: 'kubernetes')

        expect(requirements).to match_array([requirement3])
      end
    end

    shared_examples 'returns unfiltered' do
      it 'returns requirements without filtering by author' do
        expect(subject).to match_array([requirement1, requirement2, requirement3])
      end
    end

    shared_examples 'returns no items' do
      it 'returns requirements without filtering by author' do
        expect(subject).to be_empty
      end
    end

    context 'filtering by author_username' do
      subject do
        resolve_requirements(params)
      end

      context 'single author exists' do
        let(:params) do
          { author_username: [other_user.username] }
        end

        it 'filters requirements by author' do
          expect(subject).to match_array([requirement2])
        end
      end

      context 'single nonexistent author' do
        let(:params) do
          { author_username: ["nonsense"] }
        end

        it_behaves_like 'returns no items'
      end

      context 'multiple nonexistent authors' do
        let(:params) do
          { author_username: %w[undefined123 nonsense] }
        end

        it_behaves_like 'returns no items'
      end

      context 'single author is not supplied' do
        let(:params) do
          {}
        end

        it_behaves_like 'returns unfiltered'
      end

      context 'an empty array' do
        let(:params) do
          { author_username: [] }
        end

        it_behaves_like 'returns unfiltered'
      end

      context 'multiple authors' do
        let(:params) do
          { author_username: [other_user.username, current_user.username] }
        end

        it 'filters requirements by author' do
          expect(subject).to match_array([requirement1, requirement2])
        end
      end

      context 'multiple authors, one of whom does not exist' do
        let(:params) do
          { author_username: [other_user.username, 'nonsense'] }
        end

        it 'filters requirements by author' do
          expect(subject).to match_array([requirement2])
        end
      end
    end

    def resolve_requirements(args = {}, context = { current_user: current_user })
      resolve(described_class, obj: project, args: args, ctx: context)
    end
  end
end
