# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::UserAccess do
  include ProjectForksHelper

  let(:access) { described_class.new(user, container: project) }
  let(:project) { create(:project, :repository) }
  let(:user) { create(:user) }

  describe '#can_push_to_branch?' do
    describe 'push to none protected branch' do
      it 'returns true if user is a maintainer' do
        project.add_maintainer(user)

        expect(access.can_push_to_branch?('random_branch')).to be_truthy
      end

      it 'returns true if user is a developer' do
        project.add_developer(user)

        expect(access.can_push_to_branch?('random_branch')).to be_truthy
      end

      it 'returns false if user is a reporter' do
        project.add_reporter(user)

        expect(access.can_push_to_branch?('random_branch')).to be_falsey
      end
    end

    describe 'push to branch in an internal project' do
      it 'will not infinitely loop when a project is internal' do
        project.visibility_level = Gitlab::VisibilityLevel::INTERNAL
        project.save!

        expect(project).not_to receive(:branch_allows_collaboration?)

        access.can_push_to_branch?('master')
      end
    end

    describe 'push to empty project' do
      let(:empty_project) { create(:project_empty_repo) }
      let(:project_access) { described_class.new(user, container: empty_project) }

      it 'returns true for admins' do
        user.update!(admin: true)

        expect(access.can_push_to_branch?('master')).to be_truthy
      end

      it 'returns true if user is maintainer' do
        empty_project.add_maintainer(user)

        expect(project_access.can_push_to_branch?('master')).to be_truthy
      end

      context 'when the user is a developer' do
        using RSpec::Parameterized::TableSyntax

        before do
          empty_project.add_developer(user)
        end

        where(:default_branch_protection_level, :result) do
          Gitlab::Access::PROTECTION_NONE          | true
          Gitlab::Access::PROTECTION_DEV_CAN_PUSH  | true
          Gitlab::Access::PROTECTION_DEV_CAN_MERGE | false
          Gitlab::Access::PROTECTION_FULL          | false
        end

        with_them do
          it do
            expect(empty_project.namespace).to receive(:default_branch_protection).and_return(default_branch_protection_level).at_least(:once)

            expect(project_access.can_push_to_branch?('master')).to eq(result)
          end
        end
      end
    end

    describe 'push to protected branch' do
      let(:branch) { create :protected_branch, project: project, name: "test" }
      let(:not_existing_branch) { create :protected_branch, :developers_can_merge, project: project }

      it 'returns true for admins' do
        user.update!(admin: true)

        expect(access.can_push_to_branch?(branch.name)).to be_truthy
      end

      it 'returns true if user is a maintainer' do
        project.add_maintainer(user)

        expect(access.can_push_to_branch?(branch.name)).to be_truthy
      end

      it 'returns false if user is a developer' do
        project.add_developer(user)

        expect(access.can_push_to_branch?(branch.name)).to be_falsey
      end

      it 'returns false if user is a reporter' do
        project.add_reporter(user)

        expect(access.can_push_to_branch?(branch.name)).to be_falsey
      end

      it 'returns false if branch does not exist' do
        project.add_developer(user)

        expect(access.can_push_to_branch?(not_existing_branch.name)).to be_falsey
      end
    end

    describe 'push to protected branch if allowed for developers' do
      before do
        @branch = create :protected_branch, :developers_can_push, project: project
      end

      it 'returns true if user is a maintainer' do
        project.add_maintainer(user)

        expect(access.can_push_to_branch?(@branch.name)).to be_truthy
      end

      it 'returns true if user is a developer' do
        project.add_developer(user)

        expect(access.can_push_to_branch?(@branch.name)).to be_truthy
      end

      it 'returns false if user is a reporter' do
        project.add_reporter(user)

        expect(access.can_push_to_branch?(@branch.name)).to be_falsey
      end
    end

    describe 'allowing pushes to maintainers of forked projects' do
      let(:canonical_project) { create(:project, :public, :repository) }
      let(:project) { fork_project(canonical_project, create(:user), repository: true) }

      before do
        create(
          :merge_request,
          target_project: canonical_project,
          source_project: project,
          source_branch: 'awesome-feature',
          allow_collaboration: true
        )
      end

      it 'allows users that have push access to the canonical project to push to the MR branch', :sidekiq_might_not_need_inline do
        canonical_project.add_developer(user)

        expect(access.can_push_to_branch?('awesome-feature')).to be_truthy
      end

      it 'does not allow the user to push to other branches' do
        canonical_project.add_developer(user)

        expect(access.can_push_to_branch?('master')).to be_falsey
      end

      it 'does not allow the user to push if they do not have push access to the canonical project' do
        canonical_project.add_guest(user)

        expect(access.can_push_to_branch?('awesome-feature')).to be_falsey
      end
    end

    describe 'merge to protected branch if allowed for developers' do
      before do
        @branch = create :protected_branch, :developers_can_merge, project: project
      end

      it 'returns true if user is a maintainer' do
        project.add_maintainer(user)

        expect(access.can_merge_to_branch?(@branch.name)).to be_truthy
      end

      it 'returns true if user is a developer' do
        project.add_developer(user)

        expect(access.can_merge_to_branch?(@branch.name)).to be_truthy
      end

      it 'returns false if user is a reporter' do
        project.add_reporter(user)

        expect(access.can_merge_to_branch?(@branch.name)).to be_falsey
      end
    end

    context 'push to a protected branch of this project via a deploy key' do
      let(:protected_branch) { create(:protected_branch, :no_one_can_push, project: project) }

      context 'when a user cannot push to a project and branch does not allow collaboration' do
        let(:deploy_key) { create(:deploy_key, user: user) }

        before do
          project.add_guest(user)
          allow(project).to receive(:branch_allows_collaboration?).with(user, protected_branch.name).and_return(false)

          create(:deploy_keys_project, :write_access, project: protected_branch.project, deploy_key: deploy_key)
          create(:protected_branch_push_access_level, protected_branch: protected_branch, deploy_key: deploy_key)
        end

        context 'when the project has active deploy key owned by this user' do
          it 'returns true' do
            expect(access.can_push_to_branch?(protected_branch.name)).to be_truthy
          end
        end

        context 'when the project has active deploy keys, but not by this user' do
          let(:deploy_key) { create(:deploy_key, user: create(:user)) }

          it 'returns false' do
            expect(access.can_push_to_branch?(protected_branch.name)).to be_falsey
          end
        end

        context 'when there is another branch' do
          let(:another_branch) { create(:protected_branch, :no_one_can_push, project: project) }

          before do
            allow(project).to receive(:branch_allows_collaboration?).with(user, another_branch.name).and_return(false)
          end

          it 'returns false when trying to push to that other branch' do
            expect(access.can_push_to_branch?(another_branch.name)).to be_falsey
          end

          context 'and the deploy key added for the first protected branch is also added for this other branch' do
            it 'returns true for both protected branches' do
              create(:protected_branch_push_access_level, protected_branch: another_branch, deploy_key: deploy_key)

              expect(access.can_push_to_branch?(protected_branch.name)).to be_truthy
              expect(access.can_push_to_branch?(another_branch.name)).to be_truthy
            end
          end
        end
      end
    end
  end

  describe '#can_create_tag?' do
    describe 'push to none protected tag' do
      it 'returns true if user is a maintainer' do
        project.add_user(user, :maintainer)

        expect(access.can_create_tag?('random_tag')).to be_truthy
      end

      it 'returns true if user is a developer' do
        project.add_user(user, :developer)

        expect(access.can_create_tag?('random_tag')).to be_truthy
      end

      it 'returns false if user is a reporter' do
        project.add_user(user, :reporter)

        expect(access.can_create_tag?('random_tag')).to be_falsey
      end
    end

    describe 'push to protected tag' do
      let(:tag) { create(:protected_tag, project: project, name: "test") }
      let(:not_existing_tag) { create :protected_tag, project: project }

      it 'returns true if user is a maintainer' do
        project.add_user(user, :maintainer)

        expect(access.can_create_tag?(tag.name)).to be_truthy
      end

      it 'returns false if user is a developer' do
        project.add_user(user, :developer)

        expect(access.can_create_tag?(tag.name)).to be_falsey
      end

      it 'returns false if user is a reporter' do
        project.add_user(user, :reporter)

        expect(access.can_create_tag?(tag.name)).to be_falsey
      end
    end

    describe 'push to protected tag if allowed for developers' do
      before do
        @tag = create(:protected_tag, :developers_can_create, project: project)
      end

      it 'returns true if user is a maintainer' do
        project.add_user(user, :maintainer)

        expect(access.can_create_tag?(@tag.name)).to be_truthy
      end

      it 'returns true if user is a developer' do
        project.add_user(user, :developer)

        expect(access.can_create_tag?(@tag.name)).to be_truthy
      end

      it 'returns false if user is a reporter' do
        project.add_user(user, :reporter)

        expect(access.can_create_tag?(@tag.name)).to be_falsey
      end
    end
  end

  describe '#can_delete_branch?' do
    describe 'delete unprotected branch' do
      it 'returns true if user is a maintainer' do
        project.add_user(user, :maintainer)

        expect(access.can_delete_branch?('random_branch')).to be_truthy
      end

      it 'returns true if user is a developer' do
        project.add_user(user, :developer)

        expect(access.can_delete_branch?('random_branch')).to be_truthy
      end

      it 'returns false if user is a reporter' do
        project.add_user(user, :reporter)

        expect(access.can_delete_branch?('random_branch')).to be_falsey
      end
    end

    describe 'delete protected branch' do
      let(:branch) { create(:protected_branch, project: project, name: "test") }

      it 'returns true if user is a maintainer' do
        project.add_user(user, :maintainer)

        expect(access.can_delete_branch?(branch.name)).to be_truthy
      end

      it 'returns false if user is a developer' do
        project.add_user(user, :developer)

        expect(access.can_delete_branch?(branch.name)).to be_falsey
      end

      it 'returns false if user is a reporter' do
        project.add_user(user, :reporter)

        expect(access.can_delete_branch?(branch.name)).to be_falsey
      end
    end
  end
end
