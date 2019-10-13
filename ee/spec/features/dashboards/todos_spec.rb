# frozen_string_literal: true

require 'spec_helper'

describe 'Dashboard todos' do
  set(:user) { create(:user) }
  set(:author)  { create(:user) }
  set(:project) { create(:project, :public) }
  set(:issue) { create(:issue, project: project) }
  let(:page_path) { dashboard_todos_path }

  it_behaves_like 'dashboard gold trial callout'

  context 'User has a todo regarding a design' do
    set(:target) { create(:design, issue: issue) }
    set(:note) { create(:note, project: project, note: "I am note, hear me roar") }
    set(:todo) do
      create(:todo, :mentioned,
             user: user,
             project: project,
             target: target,
             author: author,
             note: note)
    end

    before do
      sign_in(user)
      project.add_developer(user)

      visit page_path
    end

    it 'has todo present' do
      expect(page).to have_selector('.todos-list .todo', count: 1)
    end

    it 'has a link that will take me to the design page' do
      click_link "design #{target.to_reference}"

      expectation = Gitlab::Routing.url_helpers.designs_project_issue_path(
        target.project, target.issue, target.filename
      )

      expect(current_path).to eq(expectation)
    end
  end
end
