# frozen_string_literal: true

require 'spec_helper'

describe 'Multiple Issue Boards', :js do
  set(:user) { create(:user) }
  set(:group) { create(:group, :public) }
  set(:planning) { create(:group_label, group: group, name: 'Planning') }
  set(:board) { create(:board, group: group) }
  let(:parent) { group }
  let(:boards_path) { group_boards_path(group) }

  context 'with multiple group issue boards disabled' do
    before do
      stub_licensed_features(multiple_group_issue_boards: false)

      parent.add_maintainer(user)

      login_as(user)
    end

    it 'does not show board switcher' do
      visit boards_path
      wait_for_requests

      expect(page).not_to have_css('.boards-switcher')
    end

    it 'shows the board switcher when group has more than one board' do
      create(:board, parent: parent)

      visit boards_path
      wait_for_requests

      expect(page).to have_css('.boards-switcher')
    end

    it 'shows license warning when group has more than one board' do
      create(:board, parent: parent)

      visit boards_path
      wait_for_requests

      click_button board.name

      expect(page).to have_content('Some of your boards are hidden, activate a license to see them again.')
    end
  end

  context 'with multiple group issue boards enabled' do
    let!(:board2) { create(:board, group: group) }

    before do
      stub_licensed_features(multiple_group_issue_boards: true)
    end

    it_behaves_like 'multiple issue boards'
  end
end
