# frozen_string_literal: true

require 'securerandom'

module QA
  # Failure issue: https://gitlab.com/gitlab-org/gitlab/issues/34936
  context 'Plan', :quarantine do
    describe 'Group issue boards' do
      let(:board_1) { "Board-1-#{SecureRandom.hex(4)}" }
      let(:board_2) { "Board-2-#{SecureRandom.hex(4)}" }

      let(:group) do
        QA::Resource::Group.fabricate_via_api!
      end

      before do
        Flow::Login.sign_in

        create_group_board(board_1)
        create_group_board(board_2)

        Page::Main::Menu.perform(&:go_to_groups)
        Page::Dashboard::Groups.perform do |groups|
          groups.click_group(group.path)
        end
        Page::Group::Menu.perform(&:go_to_issue_boards)
      end

      it 'deletes a group issue board via the GUI' do
        EE::Page::Component::IssueBoard::Show.perform do |show|
          show.delete_current_board
          show.click_boards_dropdown_button

          expect(show.boards_dropdown_content).not_to have_content(board_1)
          expect(show.boards_dropdown_content).to have_content(board_2)
        end
      end

      def create_group_board(name)
        QA::EE::Resource::Board::GroupBoard.fabricate_via_api! do |group_board|
          group_board.group = group
          group_board.name = name
        end
      end
    end
  end
end
