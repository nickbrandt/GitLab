# frozen_string_literal: true

module QA
  RSpec.describe 'Manage' do
    describe 'User with minimal access to group', :requires_admin do
      let(:user_with_minimal_access) { Resource::User.fabricate_via_api! }

      let(:group) do
        group = Resource::Group.fabricate_via_api!
        group.sandbox.add_member(user_with_minimal_access, Resource::Members::AccessLevel::MINIMAL_ACCESS)
        group
      end

      let(:project) do
        Resource::Project.fabricate_via_api! do |project|
          project.group = group
          project.name = "project-for-minimal-access"
          project.initialize_with_readme = true
        end
      end

      it 'is not allowed to edit files via the UI', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/1071' do
        Flow::Login.sign_in(as: user_with_minimal_access)
        project.visit!

        Page::Project::Show.perform do |project|
          project.click_file('README.md')
        end

        Page::File::Show.perform(&:click_edit)

        expect(page).to have_text("You're not allowed to edit files in this project directly.")
      end

      after do
        user_with_minimal_access.remove_via_api!
        project.remove_via_api!
        group.remove_via_api!
      end
    end
  end
end
