# frozen_string_literal: true

require 'spec_helper'

describe UsersOpsDashboardProjects::CreateService do
  let(:user) { create(:user) }
  let(:service) { described_class.new(user) }
  let(:project) { create(:project, :private) }

  describe '#execute' do
    context 'with at least developer access level' do
      before do
        project.add_developer(user)
      end

      it 'adds a project' do
        result = service.execute([project.id])

        expect(result).to eq(expected_result(added_project_ids: [project.id]))
      end

      it 'adds a project with a string id' do
        result = service.execute([project.id.to_s])

        expect(result).to eq(expected_result(added_project_ids: [project.id]))
      end

      it 'adds a project only once' do
        result = service.execute([project.id, project.id])

        expect(result).to eq(expected_result(added_project_ids: [project.id]))
      end

      context 'with already added project' do
        before do
          user.ops_dashboard_projects << project
        end

        it 'does not add duplicates' do
          result = service.execute([project.id])

          expect(result).to eq(expected_result(duplicate_project_ids: [project.id]))
        end
      end

      context 'checking plans' do
        using RSpec::Parameterized::TableSyntax

        where(:check_namespace_plan, :plan, :can_add) do
          true  | :gold_plan   | true
          true  | :silver_plan | false
          true  | nil          | false
          false | :gold_plan   | true
          false | :silver_plan | true
          false | nil          | true
        end

        with_them do
          before do
            stub_application_setting(check_namespace_plan: check_namespace_plan)
            project.namespace.update!(plan: create(plan)) if plan
          end

          subject { service.execute([project.id]) }

          if params[:can_add]
            it 'adds a project' do
              expect(subject).to eq(expected_result(added_project_ids: [project.id]))
            end
          else
            it 'is not allowed to add a project' do
              expect(subject).to eq(expected_result(invalid_project_ids: [project.id]))
            end
          end
        end
      end
    end

    context 'with access level lower than developer' do
      before do
        project.add_reporter(user)
      end

      it 'does not add a project' do
        result = service.execute([project.id])

        expect(result).to eq(expected_result(invalid_project_ids: [project.id]))
      end
    end

    context 'with invalid project ids' do
      let(:invalid_ids) { [nil, -1, '-1', :symbol] }

      it 'does not add invalid project ids' do
        result = service.execute(invalid_ids)

        expect(result).to eq(expected_result(invalid_project_ids: invalid_ids))
      end
    end
  end

  private

  def expected_result(
    added_project_ids: [],
    invalid_project_ids: [],
    duplicate_project_ids: []
  )
    UsersOpsDashboardProjects::CreateService::Result.new(
      added_project_ids, invalid_project_ids, duplicate_project_ids
    )
  end
end
