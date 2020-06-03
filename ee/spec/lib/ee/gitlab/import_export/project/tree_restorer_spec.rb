# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Gitlab::ImportExport::Project::TreeRestorer do
  include ImportExport::CommonUtil

  let(:shared) { project.import_export_shared }
  let(:project_tree_restorer) { described_class.new(user: user, shared: shared, project: project) }

  subject(:restored_project_json) { project_tree_restorer.restore }

  describe 'epics' do
    let_it_be(:user) { create(:user)}

    before do
      setup_import_export_config('group')
    end

    context 'with group' do
      let(:issue) { project.issues.find_by_title('Issue with Epic') }
      let!(:project) do
        create(:project,
               :builds_disabled,
               :issues_disabled,
               name: 'project',
               path: 'project',
               group: create(:group, :private))
      end

      context 'with pre-existing epic' do
        let!(:epic) { create(:epic, title: 'An epic', group: project.group) }

        it 'associates epics' do
          project = Project.find_by_path('project')

          expect { restored_project_json }.not_to change { Epic.count }
          expect(project.group.epics.count).to eq(1)
          expect(issue.epic).to eq(epic)
          expect(issue.epic_issue.relative_position).not_to be_nil
        end
      end

      context 'without pre-existing epic' do
        it 'creates epic' do
          project = Project.find_by_path('project')

          expect { restored_project_json }.to change { Epic.count }.from(0).to(1)
          expect(project.group.epics.count).to eq(1)

          expect(issue.epic).not_to be_nil
          expect(issue.epic_issue.relative_position).not_to be_nil
        end
      end
    end

    context 'with personal namespace' do
      let!(:project) do
        create(:project,
               :builds_disabled,
               :issues_disabled,
               name: 'project',
               path: 'project',
               namespace: user.namespace)
      end

      it 'ignores epic relation' do
        project = Project.find_by_path('project')

        expect { restored_project_json }.not_to change { Epic.count }
        expect(project.import_failures.size).to eq(0)
      end
    end
  end

  describe 'restores `protected_environments` with `deploy_access_levels`' do
    let_it_be(:user) { create(:admin, email: 'user_1@gitlabexample.com') }
    let_it_be(:second_user) { create(:user, email: 'user_2@gitlabexample.com') }
    let_it_be(:project) do
      create(:project, :builds_disabled, :issues_disabled,
             { name: 'project', path: 'project' })
    end

    before do
      setup_import_export_config('complex')
      restored_project_json
    end

    specify do
      aggregate_failures do
        expect(project.protected_environments.count).to eq(1)

        protected_env = project.protected_environments.first
        expect(protected_env.deploy_access_levels.count).to eq(1)
      end
    end
  end
end
