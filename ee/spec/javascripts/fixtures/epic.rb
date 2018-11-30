# frozen_string_literal: true

require 'spec_helper'

describe 'Epics (JavaScript fixtures)' do
  include ApplicationHelper
  include JavaScriptFixturesHelpers

  let(:user) { create(:user) }
  let(:group) { create(:group, name: 'frontend-fixtures-group' )}
  let(:label) { create(:group_label, group: group, title: 'bug') }
  let(:public_project) { create(:project, :public, group: group) }
  let(:milestone1) { create(:milestone, group: group, title: 'Decade A', start_date: '2010-01-01', due_date: '2019-12-31')}
  let(:milestone2) { create(:milestone, group: group, title: 'Decade B', start_date: '2020-01-01', due_date: '2029-12-31')}
  let(:issue1) { create(:issue, project: public_project, milestone: milestone1)}
  let(:issue2) { create(:issue, project: public_project, milestone: milestone2)}

  let(:markdown) do
    <<-MARKDOWN.strip_heredoc
    This is an Epic description.

    This is a task list:

    - [ ] Incomplete entry 1
    MARKDOWN
  end

  let(:epic) { create(:epic, group: group, title: 'This is a sample epic', description: markdown, start_date_fixed: '2018-06-01', due_date_fixed: '2018-08-01') }

  let!(:epic_issues) do
    [
      create(:epic_issue, epic: epic, issue: issue1, relative_position: 1),
      create(:epic_issue, epic: epic, issue: issue2, relative_position: 2)
    ]
  end

  before(:all) do
    clean_frontend_fixtures('epic/')
  end

  describe EpicsHelper, '(JavaScript fixtures)', type: :helper do
    before do
      allow(helper).to receive(:current_user).and_return(user)
    end

    it 'epic/mock_meta.json' do |example|
      result = helper.epic_show_app_data(epic, initial: {}, author_icon: 'icon_path')
      store_frontend_fixture(result.to_json, example.description)
    end
  end

  describe IssuablesHelper, '(JavaScript fixtures)', type: :helper do
    before do
      allow(helper).to receive(:current_user).and_return(user)
      allow(helper).to receive(:can?).and_return(true)
    end

    it 'epic/mock_data.json' do |example|
      @group = epic.group

      result = helper.issuable_initial_data(epic)
      store_frontend_fixture(result.to_json, example.description)
    end
  end
end
