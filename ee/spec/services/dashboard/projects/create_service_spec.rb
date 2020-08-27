# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Dashboard::Projects::CreateService do
  let(:user) { create(:user) }
  let(:service) { described_class.new(user, user.ops_dashboard_projects, feature: :operations_dashboard) }
  let(:project) { create(:project) }

  describe '#execute' do
    let(:projects_finder) { double(ProjectsFinder) }
    let(:result) { service.execute(input) }
    let(:feature_available) { true }

    before do
      allow(ProjectsFinder)
        .to receive(:new).with(current_user: user, project_ids_relation: input, params: { min_access_level: ProjectMember::DEVELOPER }).and_return(projects_finder)
      allow(projects_finder)
        .to receive(:execute).and_return(output)
      allow(project).to receive(:feature_available?).and_return(feature_available)
    end

    context 'with projects' do
      let(:output) { [project] }

      context 'with integer id' do
        let(:input) { [project.id] }

        it 'adds a project' do
          expect(result).to eq(expected_result(added_project_ids: [project.id]))
        end
      end

      context 'with string id' do
        let(:input) { [project.id.to_s] }

        it 'adds a project' do
          expect(result).to eq(expected_result(added_project_ids: [project.id]))
        end
      end

      context 'with project without provided feature enabled' do
        let(:input) { [project.id] }
        let(:output) { [] }

        it 'does not add a not found project' do
          expect(result).to eq(expected_result(not_found_project_ids: [project.id]))
        end
      end

      context 'with project without provided feature enabled' do
        let(:input) { [project.id] }
        let(:feature_available) { false }

        it 'does not add a not licensed project' do
          expect(result).to eq(expected_result(not_licensed_project_ids: [project.id]))
        end
      end

      context 'with repeating project id' do
        let(:input) { [project.id, project.id] }

        it 'adds a project only once' do
          expect(result).to eq(expected_result(added_project_ids: [project.id]))
        end
      end

      context 'with already added project' do
        let(:input) { [project.id] }

        before do
          user.ops_dashboard_projects << project
        end

        it 'does not add duplicates' do
          expect(result).to eq(expected_result(duplicate_project_ids: [project.id]))
        end
      end
    end
  end

  private

  def expected_result(
    added_project_ids: [],
    not_found_project_ids: [],
    not_licensed_project_ids: [],
    duplicate_project_ids: []
  )
    described_class::Result.new(
      added_project_ids, not_found_project_ids, not_licensed_project_ids, duplicate_project_ids
    )
  end
end
