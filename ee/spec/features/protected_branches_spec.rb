# frozen_string_literal: true

require 'spec_helper'

describe 'Protected Branches', :js do
  include ProtectedBranchHelpers

  let(:user) { create(:user, :admin) }
  let(:project) { create(:project, :repository) }

  before do
    sign_in(user)
  end

  describe 'access control' do
    describe 'with ref permissions for users enabled' do
      before do
        stub_licensed_features(protected_refs_for_users: true)
      end

      include_examples 'protected branches > access control > EE'
    end

    describe 'with ref permissions for users disabled' do
      before do
        stub_licensed_features(protected_refs_for_users: false)
      end

      include_examples 'protected branches > access control > CE'

      context 'with existing access levels' do
        let(:protected_branch) { create(:protected_branch, project: project) }

        it 'shows users that can push to the branch' do
          protected_branch.push_access_levels.new(user: create(:user, name: 'Jane'))
            .save!(validate: false)

          visit project_settings_repository_path(project)

          expect(page).to have_content("The following user can also push to this branch: "\
                                       "Jane")
        end

        it 'shows groups that can push to the branch' do
          protected_branch.push_access_levels.new(group: create(:group, name: 'Team Awesome'))
            .save!(validate: false)

          visit project_settings_repository_path(project)

          expect(page).to have_content("Members of this group can also push to "\
                                       "this branch: Team Awesome")
        end

        it 'shows users that can merge into the branch' do
          protected_branch.merge_access_levels.new(user: create(:user, name: 'Jane'))
            .save!(validate: false)

          visit project_settings_repository_path(project)

          expect(page).to have_content("The following user can also merge into "\
                                       "this branch: Jane")
        end

        it 'shows groups that have can push to the branch' do
          protected_branch.merge_access_levels.new(group: create(:group, name: 'Team Awesome'))
            .save!(validate: false)
          protected_branch.merge_access_levels.new(group: create(:group, name: 'Team B'))
            .save!(validate: false)

          visit project_settings_repository_path(project)

          expect(page).to have_content("Members of these groups can also merge into "\
                                       "this branch:")
          expect(page).to have_content(/(Team Awesome|Team B) and (Team Awesome|Team B)/)
        end
      end
    end
  end
end
