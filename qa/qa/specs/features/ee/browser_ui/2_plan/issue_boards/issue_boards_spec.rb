# frozen_string_literal: true

module QA
  context 'Plan' do
    describe 'Issue boards' do
      before do
        Runtime::Browser.visit(:gitlab, Page::Main::Login)
        Page::Main::Login.perform(&:sign_in_using_credentials)
      end

      context 'Group level' do
        let(:board_1) { 'Upstream 1' }
        let(:board_2) { 'Upstream 2' }
        let(:board_3) { 'Upstream 3' }

        let(:group) do
          QA::Resource::Group.fabricate_via_api!
        end

        before do
          create_group_board(board_1)
          create_group_board(board_2)
          create_group_board(board_3)

          page.visit("#{group.web_url}/-/boards")
        end

        it 'shows multiple group boards in the boards dropdown menu' do
          EE::Page::Group::Issue::Board::Show.perform do |show|
            show.click_boards_dropdown_button

            expect(show.boards_dropdown_content).to have_content(board_1)
            expect(show.boards_dropdown_content).to have_content(board_2)
            expect(show.boards_dropdown_content).to have_content(board_3)
          end
        end

        def create_group_board(name)
          QA::EE::Resource::Board::GroupBoard.fabricate_via_api! do |group_board|
            group_board.group = group
            group_board.name = name
          end
        end
      end

      context 'Project level' do
        let(:issue_title) { 'Issue to test board list' }

        context 'Label issue board' do
          let(:label) { 'Doing' }

          let(:label_board_list) do
            EE::Resource::Board::BoardList::Project::LabelBoardList.fabricate_via_api!
          end

          before do
            Resource::Issue.fabricate_via_api! do |issue|
              issue.project = label_board_list.project
              issue.title = issue_title
              issue.labels = [label]
            end

            label_board_list.project.visit!
            Page::Project::Menu.perform(&:go_to_boards)
          end

          it 'shows the just created board with a "Doing" (label) list, and an issue on it' do
            EE::Page::Project::Issue::Board::Show.perform do |show|
              expect(show.boards_dropdown).to have_content(label_board_list.board.name)
              expect(show.boards_list_header_with_index(1)).to have_content(label)
              expect(show.boards_list_cards_area_with_index(1)).to have_content(label)
              expect(show.card_of_list_with_index(1)).to have_content(issue_title)
            end
          end
        end

        context 'Milestone issue board' do
          let(:milestone_board_list) do
            EE::Resource::Board::BoardList::Project::MilestoneBoardList.fabricate_via_api!
          end

          before do
            Resource::Issue.fabricate_via_api! do |issue|
              issue.project = milestone_board_list.project
              issue.title = issue_title
              issue.milestone = milestone_board_list.project_milestone
            end

            milestone_board_list.project.visit!
            Page::Project::Menu.perform(&:go_to_boards)
          end

          it 'shows the just created board with a "1.0" (milestone) list, and an issue on it' do
            EE::Page::Project::Issue::Board::Show.perform do |show|
              expect(show.boards_dropdown).to have_content(milestone_board_list.board.name)
              expect(show.boards_list_header_with_index(1)).to have_content('1.0')
              expect(show.card_of_list_with_index(1)).to have_content(issue_title)
            end
          end
        end
      end
    end
  end
end
