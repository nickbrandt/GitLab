require 'spec_helper'

describe 'Epic in issue sidebar', :js do
  let(:user) { create(:user) }
  let(:group) { create(:group, :public) }
  let(:epic) { create(:epic, group: group) }
  let(:project) { create(:project, :public, group: group) }
  let(:issue) { create(:issue, project: project) }
  let!(:epic_issue) { create(:epic_issue, epic: epic, issue: issue) }

  shared_examples 'epic in issue sidebar' do
    it 'shows epic in issue sidebar for projects with group' do
      visit project_issue_path(project, issue)

      expect(page.find('.block.epic .value')).to have_content(epic.title)
    end

    it 'does not show epic in issue sidebar for personal projects' do
      personal_project = create(:project, :public)
      other_issue = create(:issue, project: personal_project)

      visit project_issue_path(personal_project, other_issue)

      expect_no_epic
    end
  end

  context 'when epics available' do
    before do
      stub_licensed_features(epics: true)

      sign_in(user)
      visit project_issue_path(project, issue)
      wait_for_requests
    end

    it_behaves_like 'epic in issue sidebar'

    context 'with namespaced plans' do
      before do
        stub_application_setting(check_namespace_plan: true)
      end

      context 'group has license' do
        before do
          create(:gitlab_subscription, :gold, namespace: group)
        end

        it_behaves_like 'epic in issue sidebar'
      end

      context 'group has no license' do
        it 'does not show epic for public projects and groups' do
          visit project_issue_path(project, issue)

          expect_no_epic
        end
      end
    end
  end

  context 'when epics unavailable' do
    before do
      stub_licensed_features(epics: false)
    end

    it 'does not show epic in issue sidebar' do
      visit project_issue_path(project, issue)

      expect_no_epic
    end
  end

  def expect_no_epic
    expect(page).not_to have_selector('.block.epic')
  end
end
