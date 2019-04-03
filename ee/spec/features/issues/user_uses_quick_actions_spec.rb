# frozen_string_literal: true

require 'rails_helper'

describe 'Issues > User uses quick actions', :js do
  include Spec::Support::Helpers::Features::NotesHelpers

  describe 'issue-only commands' do
    let(:user) { create(:user) }
    let(:project) { create(:project, :public, :repository) }
    let(:issue) { create(:issue, project: project) }

    before do
      project.add_maintainer(user)
      sign_in(user)
      visit project_issue_path(project, issue)
      wait_for_all_requests
    end

    after do
      wait_for_requests
    end

    describe 'adding a weight from a note' do
      context 'when the user can update the weight' do
        it 'does not create a note, and sets the weight accordingly' do
          add_note("/weight 5")

          expect(page).not_to have_content '/weight 5'
          expect(page).to have_content 'Commands applied'

          issue.reload

          expect(issue.weight).to eq(5)
        end
      end

      context 'when the current user cannot update the weight' do
        let(:guest) { create(:user) }
        before do
          project.add_guest(guest)
          gitlab_sign_out
          sign_in(guest)
          visit project_issue_path(project, issue)
        end

        it 'does not create a note or set the weight' do
          add_note("/weight 5")

          expect(page).not_to have_content 'Commands applied'

          issue.reload

          expect(issue.weight).not_to eq(5)
        end
      end
    end

    describe 'removing weight from a note' do
      let(:issue) { create(:issue, project: project, weight: 1) }

      context 'when the user can update the weight' do
        it 'does not create a note, and removes the weight accordingly' do
          add_note("/clear_weight")

          expect(page).not_to have_content '/clear_weight'
          expect(page).to have_content 'Commands applied'

          issue.reload

          expect(issue.weight).to eq(nil)
        end
      end

      context 'when the current user cannot update the weight' do
        let(:guest) { create(:user) }
        before do
          project.add_guest(guest)
          gitlab_sign_out
          sign_in(guest)
          visit project_issue_path(project, issue)
        end

        it 'does create a note or set the weight' do
          add_note("/clear_weight")

          expect(page).not_to have_content 'Commands applied'

          issue.reload

          expect(issue.weight).to eq(1)
        end
      end
    end
  end
end
