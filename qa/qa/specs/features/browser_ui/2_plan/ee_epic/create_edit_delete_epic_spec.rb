# frozen_string_literal: true

module QA
  context 'Plan' do
    describe 'Epics Management' do
      before do
        Runtime::Browser.visit(:gitlab, Page::Main::Login)
        Page::Main::Login.perform(&:sign_in_using_credentials)
      end

      it 'creates, edits, and deletes an epic' do
        epic_title = 'Epic created via GUI'
        epic = EE::Resource::Epic.fabricate_via_browser_ui! do |epic|
          epic.title = epic_title
        end

        expect(page).to have_content(epic_title)

        EE::Page::Group::Epic::Show.perform(&:click_edit_button)
        EE::Page::Group::Epic::Edit.perform do |edit_page|
          edited_title = 'Epic edited via GUI'
          edit_page.set_title(edited_title)
          edit_page.save_changes

          expect(edit_page).to have_content(edited_title)
        end

        epic.visit!
        EE::Page::Group::Epic::Show.perform(&:click_edit_button)
        EE::Page::Group::Epic::Edit.perform do |edit_page|
          edit_page.delete_epic

          expect(edit_page).to have_content('The epic was successfully deleted')
        end
      end

      it 'adds/removes issue to/from epic' do
        create_resources_and_visit_epic_page

        EE::Page::Group::Epic::Show.perform do |show_page|
          show_page.add_issue_to_epic(@issue.web_url)
          expect(show_page).to have_content('added issue')

          show_page.remove_issue_from_epic
          expect(show_page).to have_content('removed issue')
        end
      end

      it 'comments on epic' do
        create_resources_and_visit_epic_page

        comment = 'My Epic Comment'
        EE::Page::Group::Epic::Show.perform do |show_page|
          show_page.add_comment_to_epic(comment)
        end

        expect(page).to have_content(comment)
      end

      it 'closes and reopens an epic' do
        create_resources_and_visit_epic_page

        EE::Page::Group::Epic::Show.perform(&:close_reopen_epic)

        expect(page).to have_content('Closed')

        EE::Page::Group::Epic::Show.perform(&:close_reopen_epic)

        expect(page).to have_content('Open')
      end

      it 'adds/removes issue to/from epic using quick actions' do
        create_resources_and_visit_epic_page

        @issue.visit!

        Page::Project::Issue::Show.perform do |show_page|
          show_page.wait_for_related_issues_to_load
          show_page.comment("/epic #{@epic_web_url}")
          show_page.comment("/remove_epic")
          expect(show_page).to have_content('removed from epic')
        end

        page.visit @epic_web_url

        expect(page).to have_content('added issue')
        expect(page).to have_content('removed issue')
      end

      def create_resources_and_visit_epic_page
        @issue = Resource::Issue.fabricate_via_api! do |issue|
          issue.title = 'Issue created via API'
          issue.labels = []
        end

        @epic = EE::Resource::Epic.fabricate_via_api! do |epic|
          epic.group = @issue.project.group.id
          epic.title = 'Epic created via API'
        end

        # Epics have no web_url exposed via the API, and so we build it here.
        # Related issue: https://gitlab.com/gitlab-org/gitlab-ee/issues/11241
        @epic_web_url = "#{@issue.project.group.web_url}/-/epics/1"
        page.visit @epic_web_url
      end
    end
  end
end
