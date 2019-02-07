# frozen_string_literal: true

module QA
  # Failure issue: https://gitlab.com/gitlab-org/quality/staging/issues/29
  context 'Plan', :quarantine do
    describe 'promote issue to epic' do
      let(:issue_title) { "My Awesome Issue #{SecureRandom.hex(8)}" }

      it 'user promotes issue to an epic' do
        Runtime::Browser.visit(:gitlab, Page::Main::Login)
        Page::Main::Login.act { sign_in_using_credentials }

        group = Resource::Group.fabricate!

        project = Resource::Project.fabricate! do |project|
          project.name = 'promote-issue-to-epic'
          project.description = 'Project to promote issue to epic'
          project.group = group
        end

        Resource::Issue.fabricate! do |issue|
          issue.title = issue_title
          issue.project = project
        end

        Page::Project::Issue::Show.perform do |show|
          show.select_all_activities_filter
          show.comment('/promote')

          expect(show).to have_content("promoted to epic")
        end

        group.visit!
        QA::EE::Page::Group::Menu.perform(&:go_to_group_epics)
        QA::EE::Page::Group::Epic::Index.perform(&:click_first_epic)

        expect(page).to have_content(issue_title)
        expect(page).to have_content(/promoted from issue .* \(closed\)/)
      end
    end
  end
end
