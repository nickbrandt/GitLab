# frozen_string_literal: true

module QA
  context 'Create' do
    context 'Push Rules' do
      describe 'using non signed commits' do
        file_name_limitation = 'denied_file'
        file_size_limitation = 1
        authors_email_limitation = '(admin@example.com|root@gitlab.com)'
        branch_name_limitation = 'master'
        needed_phrase_limitation = 'allowed commit'
        deny_message_phrase_limitation = 'denied commit'

        before :context do
          prepare

          Page::Project::Settings::Repository.perform do |repository|
            repository.expand_push_rules do |push_rules|
              push_rules.fill_file_name file_name_limitation
              push_rules.fill_file_size file_size_limitation
              push_rules.fill_author_email authors_email_limitation
              push_rules.fill_branch_name branch_name_limitation
              push_rules.fill_commit_message_rule needed_phrase_limitation
              push_rules.fill_deny_commit_message_rule deny_message_phrase_limitation
              push_rules.check_prevent_secrets
              push_rules.check_restrict_author
              push_rules.check_deny_delete_tag
              push_rules.click_submit
            end
          end
        end

        it 'restricts files by name and size' do
          large_file = [{
            name: 'file',
            content: SecureRandom.hex(1000000)
          }]
          wrongly_named_file = [{
            name: file_name_limitation,
            content: SecureRandom.hex(100)
          }]

          expect_no_error_on_push file: standard_file
          expect_error_on_push file: large_file
          expect_error_on_push file: wrongly_named_file
        end

        it 'restricts users by email format' do
          gitlab_user = Resource::User.fabricate_or_use(Runtime::Env.gitlab_qa_username_1, Runtime::Env.gitlab_qa_password_1)

          expect_no_error_on_push file: standard_file
          expect_error_on_push file: standard_file, user: gitlab_user
        end

        it 'restricts branches by branch name' do
          expect_no_error_on_push file: standard_file
          expect_error_on_push file: standard_file, branch: 'forbidden_branch'
        end

        it 'restricts commit by message format' do
          expect_no_error_on_push file: standard_file, commit_message: needed_phrase_limitation
          expect_error_on_push file: standard_file, commit_message: 'forbidden message'
          expect_error_on_push file: standard_file, commit_message: "#{needed_phrase_limitation} - #{deny_message_phrase_limitation}"
        end

        it 'restricts committing files with secrets' do
          secret_file = [{
            name: 'id_rsa',
            content: SecureRandom.hex(100)
          }]

          expect_no_error_on_push file: standard_file
          expect_error_on_push file: secret_file
        end

        it 'restricts commits by user' do
          expect_no_error_on_push file: standard_file
          expect_error_on_push file: standard_file, user: root_user
        end

        it 'restricts removal of tag' do
          tag = Resource::Tag.fabricate_via_api! do |tag|
            tag.project = @project
            tag.ref = 'master'
            tag.name = 'test_tag'
          end

          expect_no_error_on_push file: standard_file
          expect_error_on_push file: standard_file, tag: tag.name
        end
      end

      describe 'using signed commits' do
        before :context do
          prepare

          Page::Project::Settings::Repository.perform do |repository|
            repository.expand_push_rules do |push_rules|
              push_rules.check_reject_unsigned_commits
              push_rules.check_committer_restriction
              push_rules.click_submit
            end
          end

          @gpg = Resource::UserGPG.fabricate_via_api!
        end

        it 'restricts to signed commits' do
          expect_no_error_on_push file: standard_file, gpg: @gpg
          expect_error_on_push file: standard_file
        end

        it 'restricts commits to current authenticated user' do
          gitlab_user = Resource::User.fabricate_or_use(Runtime::Env.gitlab_qa_username_1, Runtime::Env.gitlab_qa_password_1)

          expect_no_error_on_push file: standard_file, gpg: @gpg
          expect_error_on_push file: standard_file, gpg: @gpg, user: gitlab_user
        end
      end

      def standard_file
        [{
           name: 'file',
           content: SecureRandom.hex(100)
         }]
      end

      def root_user
        Resource::User.new.tap do |user|
          user.username = 'root'
          user.name = 'GitLab QA'
          user.email = 'root@gitlab.com'
          user.password = nil
        end
      end

      def push(commit_message:, branch:, file:, user:, tag:, gpg:)
        Resource::Repository::ProjectPush.fabricate! do |push|
          push.project = @project
          push.commit_message = commit_message
          push.new_branch = branch != 'master'
          push.branch_name = branch
          push.user = user
          push.files = file if tag.nil?
          push.tag_name = tag unless tag.nil?
          push.gpg_key_id = gpg.key_id unless gpg.nil?
        end
      end

      def expect_no_error_on_push(commit_message: 'allowed commit', branch: 'master', file:, user: Runtime::User, tag: nil, gpg: nil)
        expect do
          push commit_message: commit_message, branch: branch, file: file, user: user, tag: tag, gpg: gpg
        end.not_to raise_error
      end

      def expect_error_on_push(commit_message: 'allowed commit', branch: 'master', file:, user: Runtime::User, tag: nil, gpg: nil)
        expect do
          push commit_message: commit_message, branch: branch, file: file, user: user, tag: tag, gpg: gpg
        end.to raise_error(QA::Git::Repository::RepositoryCommandError)
      end

      def prepare
        Flow::Login.sign_in

        @project = Resource::Project.fabricate_via_api! do |project|
          project.name = 'push_rules'
        end

        Resource::Repository::ProjectPush.fabricate! do |push|
          push.project = @project
          push.files = standard_file
        end

        @project.visit!

        Page::Project::Menu.perform(&:go_to_repository_settings)
      end
    end
  end
end
