# frozen_string_literal: true

module QA
  context 'Plan' do
    describe 'Issue boards' do
      let(:issue_title) { 'Issue to test board list' }

      before do
        Runtime::Browser.visit(:gitlab, Page::Main::Login)
        Page::Main::Login.perform(&:sign_in_using_credentials)
      end

      context 'Label issue board' do
        let(:label) { 'Doing' }

        let(:label_board_list) do
          EE::Resource::LabelBoardList.fabricate_via_api!
        end

        before do
          Resource::Issue.fabricate_via_api! do |issue|
            issue.project = label_board_list.project
            issue.title = issue_title
            issue.labels = [label]
          end
        end

        it 'shows the just created board with a "Doing" (label) list, and an issue on it' do
          page.visit("#{label_board_list.project.web_url}/-/boards")

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
          EE::Resource::MilestoneBoardList.fabricate_via_api!
        end

        before do
          Resource::Issue.fabricate_via_api! do |issue|
            issue.project = milestone_board_list.project
            issue.title = issue_title
            issue.milestone = milestone_board_list.project_milestone
          end
        end

        it 'shows the just created board with a "1.0" (milestone) list, and an issue on it' do
          page.visit("#{milestone_board_list.project.web_url}/-/boards")

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
