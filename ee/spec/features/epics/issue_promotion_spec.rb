# frozen_string_literal: true

require 'spec_helper'

describe 'Issue promotion', :js do
  include Spec::Support::Helpers::Features::NotesHelpers

  let(:group) { create(:group) }
  let(:project) { create(:project, :public, group: group) }
  let(:issue) { create(:issue, project: project) }
  let(:user) { create(:user) }

  before do
    sign_in(user)
  end

  context 'when epics feature is disabled' do
    it 'does not promote the issue' do
      visit project_issue_path(project, issue)

      expect(page).not_to have_content 'Commands applied'

      expect(issue.reload).to be_open
      expect(Epic.count).to be_zero
    end
  end

  context 'when epics feature is enabled' do
    before do
      stub_licensed_features(epics: true)
    end

    context 'when current user does not have permissions to promote an issue' do
      before do
        visit project_issue_path(project, issue)
      end

      it 'does not promote the issue' do
        expect(page).not_to have_content 'Commands applied'

        expect(issue.reload).to be_open
        expect(Epic.count).to be_zero
      end
    end

    context 'when current user can promote an issue' do
      before do
        group.add_developer(user)
        visit project_issue_path(project, issue)
      end

      it 'promotes the issue' do
        add_note('/promote')

        wait_for_requests

        epic = Epic.last

        expect(page).to have_content 'Commands applied'
        expect(issue.reload).to be_closed
        expect(epic.title).to eq(issue.title)
        expect(epic.description).to eq(issue.description)
        expect(epic.author).to eq(user)
      end
    end
  end
end
