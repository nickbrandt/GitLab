# frozen_string_literal: true

module QA
  context 'Plan' do
    describe 'Configurable issue board' do
      let(:label_board_list) do
        EE::Resource::Board::BoardList::Project::LabelBoardList.fabricate_via_api!
      end

      before do
        Runtime::Browser.visit(:gitlab, Page::Main::Login)
        Page::Main::Login.perform(&:sign_in_using_credentials)

        label_board_list.project.visit!
        Page::Project::Menu.perform(&:go_to_boards)
      end

      it 'shows board configuration to user without edit permission' do
        new_board_name = 'UX'

        EE::Page::Project::Issue::Board::Show.perform do |show|
          show.click_boards_config_button

          show.set_name(new_board_name)

          expect(show.boards_dropdown).to have_content(new_board_name)
        end
      end
    end
  end
end
