# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Update Epic', :js do
  include DropzoneHelper

  let(:user) { create(:user) }
  let(:group) { create(:group, :public) }

  let(:markdown) do
    <<-MARKDOWN.strip_heredoc
    This is a task list:

    - [ ] Incomplete entry 1
    MARKDOWN
  end

  let(:epic) { create(:epic, group: group, description: markdown) }

  before do
    stub_licensed_features(epics: true)

    sign_in(user)
  end

  context 'when user who is not a group member displays the epic' do
    it 'does not show the Edit button' do
      visit group_epic_path(group, epic)

      expect(page).not_to have_selector('.btn-edit')
    end
  end

  context 'when user with developer access displays the epic' do
    before do
      group.add_developer(user)
      visit group_epic_path(group, epic)
      wait_for_requests
    end

    context 'update form' do
      before do
        find('.btn-edit').click
      end

      it 'updates the epic' do
        fill_in 'issuable-title', with: 'New epic title'
        fill_in 'issue-description', with: 'New epic description'

        page.within('.detail-page-description') do
          click_button('Preview')
          expect(find('.md-preview-holder')).to have_content('New epic description')
        end

        click_button 'Save changes'

        expect(find('.issuable-details h1.title')).to have_content('New epic title')
        expect(find('.issuable-details .description')).to have_content('New epic description')
      end

      it 'updates the epic and keep the description saved across reload' do
        fill_in 'issue-description', with: 'New epic description'

        page.within('.detail-page-description') do
          click_button('Preview')
          expect(find('.md-preview-holder')).to have_content('New epic description')
        end

        visit group_epic_path(group, epic)

        # Deal with the beforeunload browser popup
        page.driver.browser.switch_to.alert.accept

        wait_for_requests
        find('.btn-edit').click

        page.within('.detail-page-description') do
          click_button('Preview')
          expect(find('.md-preview-holder')).to have_content('New epic description')
        end
      end

      it 'creates a todo only for mentioned users' do
        mentioned = create(:user)

        # Add a trailing space to close mention auto-complete dialog, which might block the save button
        fill_in 'issue-description', with: "FYI #{mentioned.to_reference} "

        click_button 'Save changes'

        expect(find('.issuable-details h1.title')).to have_content('title')

        visit dashboard_todos_path

        expect(page).to have_selector('.todos-list .todo', count: 0)

        sign_in(mentioned)

        visit dashboard_todos_path

        page.within '.header-content .todos-count' do
          expect(page).to have_content '1'
        end
        expect(page).to have_selector('.todos-list .todo', count: 1)
        within first('.todo') do
          expect(page).to have_content "epic #{epic.to_reference} \"#{epic.title}\" at #{epic.group.name}"
        end
      end

      it 'edits full screen' do
        page.within('.detail-page-description') { find('.js-zen-enter').click }

        expect(page).to have_selector('.div-dropzone-wrapper.fullscreen')
      end

      it 'uploads a file when dragging into textarea' do
        link_css = 'a.no-attachment-icon img.js-lazy-loaded[alt="banana_sample"]'
        link_match = %r{/groups/#{Regexp.escape(group.full_path)}/-/uploads/\h{32}/banana_sample\.gif\z}
        dropzone_file Rails.root.join('spec', 'fixtures', 'banana_sample.gif')

        expect(page.find_field("issue-description").value).to have_content('banana_sample')

        page.within('.detail-page-description') do
          click_button('Preview')
          wait_for_requests

          within('.md-preview-holder') do
            link = find(link_css)['src']
            expect(link).to match(link_match)
          end
        end

        click_button 'Save changes'
        wait_for_requests

        link = find(link_css)['src']
        expect(link).to match(link_match)
      end

      describe 'autocomplete enabled' do
        it 'opens atwho container' do
          find('#issue-description').native.send_keys('@')
          expect(page).to have_selector('.atwho-container')
        end
      end
    end

    context 'epic sidebar' do
      it 'opens datepicker when clicking Edit button' do
        page.within('.issuable-sidebar .block.start-date') do
          click_button('Edit')
          expect(find('.value-type-fixed')).to have_selector('.gl-datepicker')
          expect(find('.value-type-fixed')).to have_selector('.gl-datepicker .pika-single.is-bound')
        end
      end
    end

    it 'updates the tasklist' do
      expect(page).to have_selector('ul.task-list',      count: 1)
      expect(page).to have_selector('li.task-list-item', count: 1)
      expect(page).to have_selector('ul input[checked]', count: 0)

      find('.task-list .task-list-item', text: 'Incomplete entry 1').find('input').click

      expect(page).to have_selector('ul input[checked]', count: 1)
    end
  end

  context 'when user with owner access displays the epic' do
    before do
      group.add_owner(user)
      visit group_epic_path(group, epic)
      wait_for_requests
    end

    it 'shows delete button inside the edit form' do
      find('.btn-edit').click

      expect(page).to have_selector('.issuable-details .btn-danger')
    end
  end
end
