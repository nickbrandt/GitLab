# frozen_string_literal: true

require 'spec_helper'

describe Dashboard::Projects::CreateService do
  let(:user) { create(:user) }
  let(:service) { described_class.new(user, user.ops_dashboard_projects, feature: :operations_dashboard) }
  let(:project) { create(:project) }

  describe '#execute' do
    let(:projects_service) { double(Dashboard::Projects::ListService) }
    let(:result) { service.execute(input) }

    before do
      allow(Dashboard::Projects::ListService)
        .to receive(:new).with(user, feature: :operations_dashboard).and_return(projects_service)
      allow(projects_service)
        .to receive(:execute).with(input).and_return(output)
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

    context 'with invalid project ids' do
      let(:input) { [nil, -1, '-1', :symbol] }
      let(:output) { [] }

      it 'does not add invalid project ids' do
        expect(result).to eq(expected_result(invalid_project_ids: input.map(&:to_s)))
      end
    end
  end

  private

  def expected_result(
    added_project_ids: [],
    invalid_project_ids: [],
    duplicate_project_ids: []
  )
    described_class::Result.new(
      added_project_ids, invalid_project_ids, duplicate_project_ids
    )
  end
end
