# frozen_string_literal: true

require 'spec_helper'

describe 'Issue Sidebar' do
  include MobileHelpers

  let(:group) { create(:group, :nested) }
  let(:project) { create(:project, :public, namespace: group) }
  let!(:user) { create(:user)}
  let!(:label) { create(:label, project: project, title: 'bug') }
  let(:issue) { create(:labeled_issue, project: project, labels: [label]) }

  before do
    sign_in(user)
  end

  context 'updating weight', :js do
    before do
      project.add_maintainer(user)
      visit_issue(project, issue)
    end

    it 'updates weight in sidebar to 1' do
      page.within '.weight' do
        click_link 'Edit'
        find('input').send_keys 1, :enter

        page.within '.value' do
          expect(page).to have_content '1'
        end
      end
    end

    it 'updates weight in sidebar to no weight' do
      page.within '.weight' do
        click_link 'Edit'
        find('input').send_keys 1, :enter

        page.within '.value' do
          expect(page).to have_content '1'
        end

        click_link 'remove weight'

        page.within '.value' do
          expect(page).to have_content 'None'
        end
      end
    end
  end

  context 'as a guest' do
    before do
      project.add_guest(user)
      visit_issue(project, issue)
    end

    it 'does not have a option to edit weight' do
      expect(page).not_to have_selector('.block.weight .js-weight-edit-link')
    end
  end

  context 'as a guest, interacting with collapsed sidebar', :js do
    before do
      project.add_guest(user)
      resize_screen_sm
      visit_issue(project, issue)
    end

    it 'edit weight field does not appear after clicking on weight when sidebar is collapsed then expanding it' do
      find('.js-weight-collapsed-block').click
      # Expand sidebar
      open_issue_sidebar
      expect(page).not_to have_selector('.block.weight .form-control')
    end
  end

  def visit_issue(project, issue)
    visit project_issue_path(project, issue)
  end

  def open_issue_sidebar
    find('aside.right-sidebar.right-sidebar-collapsed .js-sidebar-toggle').click
    find('aside.right-sidebar.right-sidebar-expanded')
  end
end
