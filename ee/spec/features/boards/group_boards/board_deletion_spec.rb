# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Group Boards', :js do
  include Spec::Support::Helpers::Features::TopNavSpecHelpers

  let(:group) { create(:group) }
  let!(:board_ux) { create(:board, group: group, name: 'UX') }
  let!(:board_dev) { create(:board, group: group, name: 'Dev') }
  let(:user) { create(:group_member, user: create(:user), group: group ).user }

  before do
    stub_licensed_features(multiple_group_issue_boards: true)
    dismiss_top_nav_callout(user)
    sign_in(user)
    visit group_boards_path(group)
    wait_for_requests
  end

  it 'deletes a group issue board' do
    click_boards_dropdown

    wait_for_requests

    find(:css, '.js-delete-board button').click
    find(:css, '.board-config-modal .js-modal-action-primary').click

    click_boards_dropdown

    page.within('.js-boards-selector') do
      expect(page).not_to have_content(board_dev.name)
      expect(page).to have_content(board_ux.name)
    end
  end

  def click_boards_dropdown
    find(:css, '.js-dropdown-toggle').click
  end
end
