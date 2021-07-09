# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Gitlab::ImportExport::Project::TreeRestorer do
  include ImportExport::CommonUtil

  subject(:restored_project_json) { project_tree_restorer.restore }

  let(:shared) { project.import_export_shared }
  let(:project_tree_restorer) { described_class.new(user: user, shared: shared, project: project) }

  describe 'epics' do
    let_it_be(:user) { create(:user)}

    before do
      setup_import_export_config('group')
    end

    context 'with group' do
      let_it_be(:project) do
        create(:project,
               :builds_disabled,
               :issues_disabled,
               name: 'project',
               path: 'project',
               group: create(:group, :private))
      end

      let(:issue) { project.issues.find_by_title('Issue with Epic') }

      context 'with pre-existing epic' do
        let_it_be(:epic) { create(:epic, title: 'An epic', group: project.group) }

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
      let_it_be(:project) do
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

  describe 'security_settings' do
    let_it_be(:project) { create(:project, name: 'project', path: 'project') }

    let(:user) { create(:user)}

    before do
      setup_import_export_config('complex', 'ee')
      restored_project_json
    end

    it 'creates security setting' do
      expect(project.security_setting.auto_fix_dependency_scanning).to be_falsey
      expect(project.security_setting.auto_fix_container_scanning).to be_truthy
    end
  end

  describe 'push_rules' do
    let_it_be(:project) { create(:project, name: 'project', path: 'project') }

    let(:user) { create(:user)}

    before do
      setup_import_export_config('complex', 'ee')
    end

    it 'creates push rules' do
      project = Project.find_by_path('project')

      expect { restored_project_json }.to change { PushRule.count }.from(0).to(1)

      expect(project.push_rule.force_push_regex).to eq("MustContain")
      expect(project.push_rule.commit_message_negative_regex).to eq("MustNotContain")
      expect(project.push_rule.max_file_size).to eq(1)
      expect(project.push_rule.deny_delete_tag).to be_truthy
    end
  end
end
