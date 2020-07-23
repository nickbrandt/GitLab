# frozen_string_literal: true

module QA
  context 'Create' do
    describe 'Codeowners' do
      context 'when the project is in a subgroup' do
        let(:approver) { Resource::User.fabricate_or_use(Runtime::Env.gitlab_qa_username_1, Runtime::Env.gitlab_qa_password_1) }
        let(:project) do
          Resource::Project.fabricate_via_api! do |project|
            project.name = "approve-and-merge"
            project.initialize_with_readme = true
          end
        end

        before do
          group_or_project.add_member(approver, Resource::Members::AccessLevel::MAINTAINER)

          Flow::Login.sign_in

          project.visit!
        end

        after do
          group_or_project.remove_member(approver)
        end

        context 'and the code owner is the root group' do
          let(:codeowner) { project.group.sandbox.path }
          let(:group_or_project) { project.group.sandbox }

          it_behaves_like 'code owner merge request'
        end

        context 'and the code owner is the subgroup' do
          let(:codeowner) { project.group.full_path }
          let(:group_or_project) { project.group }

          it_behaves_like 'code owner merge request'
        end

        context 'and the code owner is a user' do
          let(:codeowner) { approver.username }
          let(:group_or_project) { project }

          it_behaves_like 'code owner merge request'
        end
      end
    end
  end
end
