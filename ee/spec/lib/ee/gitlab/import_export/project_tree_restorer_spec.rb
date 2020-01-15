# frozen_string_literal: true
require 'spec_helper'

describe Gitlab::ImportExport::ProjectTreeRestorer do
  include ImportExport::CommonUtil
  using RSpec::Parameterized::TableSyntax

  let(:shared) { project.import_export_shared }
  let(:project_tree_restorer) { described_class.new(user: user, shared: shared, project: project) }

  subject(:restored_project_json) { project_tree_restorer.restore }

  describe 'epics' do
    let_it_be(:user) { create(:user)}

    before do
      setup_import_export_config('group')
    end

    context 'with group' do
      let!(:project) do
        create(:project,
               :builds_disabled,
               :issues_disabled,
               name: 'project',
               path: 'project',
               group: create(:group, visibility_level: Gitlab::VisibilityLevel::PRIVATE))
      end

      context 'with pre-existing epic' do
        let!(:epic) { create(:epic, title: 'An epic', group: project.group) }

        it 'associates epics' do
          project = Project.find_by_path('project')

          expect { restored_project_json }.not_to change { Epic.count }
          expect(project.group.epics.count).to eq(1)
          expect(project.issues.find_by_title('Issue with Epic').epic).not_to be_nil
        end
      end

      context 'without pre-existing epic' do
        it 'creates epic' do
          project = Project.find_by_path('project')

          expect { restored_project_json }.to change { Epic.count }.from(0).to(1)
          expect(project.group.epics.count).to eq(1)
          expect(project.issues.find_by_title('Issue with Epic').epic).not_to be_nil
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

  describe 'restoring design management data' do
    let_it_be(:user) { create(:admin, username: 'user_1') }
    let_it_be(:second_user) { create(:user, username: 'user_2' )}
    let_it_be(:project) do
      create(:project, :builds_disabled, :issues_disabled,
             { name: 'project', path: 'project' })
    end

    before do
      setup_import_export_config('designs', 'ee')
      restored_project_json
    end

    it_behaves_like 'restores project successfully', issues: 2

    it 'restores project associations correctly' do
      expect(project.designs.size).to eq(7)
    end

    describe 'restores issue associations correctly' do
      let(:issue) { project.issues.offset(index).first }

      where(:index, :design_filenames, :version_shas, :events, :author_usernames) do
        0 | %w[chirrido3.jpg jonathan_richman.jpg mariavontrap.jpeg] | %w[27702d08f5ee021ae938737f84e8fe7c38599e85 9358d1bac8ff300d3d2597adaa2572a20f7f8703 e1a4a501bcb42f291f84e5d04c8f927821542fb6] | %w[creation creation creation modification modification deletion] | %w[user_1 user_1 user_2]
        1 | ['1 (1).jpeg', '2099743.jpg', 'a screenshot (1).jpg', 'chirrido3.jpg'] | %w[73f871b4c8c1d65c62c460635e023179fb53abc4 8587e78ab6bda3bc820a9f014c3be4a21ad4fcc8 c9b5f067f3e892122a4b12b0a25a8089192f3ac8] | %w[creation creation creation creation modification] | %w[user_1 user_2 user_2]
      end

      with_them do
        it do
          expect(issue.designs.pluck(:filename)).to contain_exactly(*design_filenames)
          expect(issue.design_versions.pluck(:sha)).to contain_exactly(*version_shas)
          expect(issue.design_versions.flat_map(&:actions).map(&:event)).to contain_exactly(*events)
          expect(issue.design_versions.map(&:author).map(&:username)).to contain_exactly(*author_usernames)
        end
      end
    end

    describe 'restores design version associations correctly' do
      let(:project_designs) { project.designs.reorder(:filename, :issue_id) }
      let(:design) { project_designs.offset(index).first }

      where(:index, :version_shas) do
        0 | %w[73f871b4c8c1d65c62c460635e023179fb53abc4 c9b5f067f3e892122a4b12b0a25a8089192f3ac8]
        1 | %w[73f871b4c8c1d65c62c460635e023179fb53abc4]
        2 | %w[c9b5f067f3e892122a4b12b0a25a8089192f3ac8]
        3 | %w[27702d08f5ee021ae938737f84e8fe7c38599e85 9358d1bac8ff300d3d2597adaa2572a20f7f8703 e1a4a501bcb42f291f84e5d04c8f927821542fb6]
        4 | %w[8587e78ab6bda3bc820a9f014c3be4a21ad4fcc8]
        5 | %w[27702d08f5ee021ae938737f84e8fe7c38599e85 e1a4a501bcb42f291f84e5d04c8f927821542fb6]
        6 | %w[27702d08f5ee021ae938737f84e8fe7c38599e85]
      end

      with_them do
        it do
          expect(design.versions.pluck(:sha)).to contain_exactly(*version_shas)
        end
      end
    end

    it 'restores `protected_environments` with `deploy_access_levels`' do
      aggregate_failures do
        expect(project.protected_environments.count).to eq(1)

        protected_env = project.protected_environments.first
        expect(protected_env.deploy_access_levels.count).to eq(1)
      end
    end
  end
end
