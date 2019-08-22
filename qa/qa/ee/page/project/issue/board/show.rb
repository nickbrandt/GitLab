# frozen_string_literal: true

module QA
  module EE
    module Page
      module Project
        module Issue
          module Board
            class Show < QA::Page::Base
              view 'app/assets/javascripts/boards/components/board_card.vue' do
                element :board_card
              end

              view 'app/assets/javascripts/boards/components/board_list.vue' do
                element :board_list_cards_area
              end

              view 'app/assets/javascripts/boards/components/boards_selector.vue' do
                element :boards_dropdown
              end

              view 'app/views/shared/boards/_show.html.haml' do
                element :boards_list
              end

              view 'app/views/shared/boards/components/_board.html.haml' do
                element :board_list
                element :board_list_header
              end

              def boards_dropdown
                find_element(:boards_dropdown)
              end

              def boards_list_cards_area_with_index(index)
                wait_boards_list_finish_loading do
                  within_element_by_index(:board_list, index) do
                    find_element(:board_list_cards_area)
                  end
                end
              end

              def boards_list_header_with_index(index)
                wait_boards_list_finish_loading do
                  within_element_by_index(:board_list, index) do
                    find_element(:board_list_header)
                  end
                end
              end

              def card_of_list_with_index(index)
                wait_boards_list_finish_loading do
                  within_element_by_index(:board_list, index) do
                    find_element(:board_card)
                  end
                end
              end

              private

              def wait_boards_list_finish_loading
                within_element(:boards_list) do
                  wait(reload: false, max: 5, interval: 1) do
                    finished_loading?
                    yield
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
