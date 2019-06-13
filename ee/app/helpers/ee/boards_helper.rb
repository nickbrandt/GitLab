# frozen_string_literal: true

module EE
  module BoardsHelper
    extend ::Gitlab::Utils::Override

    def parent
      @group || @project
    end

    override :board_list_data
    def board_list_data
      super.merge(list_milestone_path: board_milestones_path(board, :json),
                  list_assignees_path: board_users_path(board, :json))
    end

    override :board_data
    def board_data
      show_feature_promotion = (@project && show_promotions? &&
                                (!@project.feature_available?(:multiple_project_issue_boards) ||
                                 !@project.feature_available?(:scoped_issue_board) ||
                                 !@project.feature_available?(:issue_board_focus_mode)))

      data = {
        recent_boards_endpoint: recent_boards_path,
        board_milestone_title: board.milestone&.name,
        board_milestone_id: board.milestone_id,
        board_assignee_username: board.assignee&.username,
        label_ids: board.label_ids,
        labels: board.labels.to_json(only: [:id, :title, :color, :text_color] ),
        board_weight: board.weight,
        focus_mode_available: parent.feature_available?(:issue_board_focus_mode),
        weight_feature_available: parent.feature_available?(:issue_weights).to_s,
        show_promotion: show_feature_promotion,
        scoped_labels: parent.feature_available?(:scoped_labels)&.to_s,
        scoped_labels_documentation_link: help_page_path('user/project/labels.md', anchor: 'scoped-labels')
      }

      super.merge(data)
    end

    def recent_boards_path
      parent.is_a?(Group) ? recent_group_boards_path(@group) : recent_project_boards_path(@project)
    end

    def serializer
      CurrentBoardSerializer.new
    end

    def current_board
      board = @board || @boards.first

      serializer.represent(board).as_json
    end

    override :boards_link_text
    def boards_link_text
      if parent.multiple_issue_boards_available?
        s_("IssueBoards|Boards")
      else
        s_("IssueBoards|Board")
      end
    end
  end
end
