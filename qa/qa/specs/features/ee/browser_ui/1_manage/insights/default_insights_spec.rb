# frozen_string_literal: true

module QA
  context 'Manage' do
    shared_examples 'default insights page' do
      it 'displays issues and merge requests dashboards' do
        EE::Page::Insights::Show.perform do |show|
          show.wait_for_insight_charts_to_load

          expect(show).to have_insights_dashboard_title('Issues Dashboard')

          show.select_insights_dashboard('Merge Requests Dashboard')

          expect(show).to have_insights_dashboard_title('Merge Requests Dashboard')
        end
      end
    end

    context 'group insights page' do
      before do
        Flow::Login.sign_in

        group = Resource::Group.fabricate_via_api!
        group.visit!

        Page::Group::Menu.perform(&:click_group_insights_link)
      end

      it_behaves_like 'default insights page'
    end

    context 'project insights page' do
      before do
        Flow::Login.sign_in

        project = Resource::Project.fabricate_via_api! do |project|
          project.name = 'project-insights'
          project.description = 'Project Insights'
        end

        project.visit!

        Page::Project::Menu.perform(&:click_project_insights_link)
      end

      it_behaves_like 'default insights page'
    end
  end
end
