# frozen_string_literal: true

module EE
  module BoardsActions
    extend ActiveSupport::Concern

    prepended do
      # We need to include the filters as a separate concern since multiple `included` blocks are not allowed
      include Filters
    end

    module Filters
      extend ActiveSupport::Concern

      included do
        before_action :redirect_to_recent_board, only: :index
        before_action :authenticate_user!, only: [:recent]
        before_action :authorize_create_board!, only: [:create]
        before_action :authorize_admin_board!, only: [:create, :update, :destroy]
      end
    end

    def recent
      recent_visits = ::Boards::Visits::LatestService.new(parent, current_user, count: 4).execute
      recent_boards = recent_visits.map(&:board)

      render json: serialize_as_json(recent_boards)
    end

    def create
      board = ::Boards::CreateService.new(parent, current_user, board_params).execute

      respond_to do |format|
        format.json do
          if board.valid?
            extra_json = { board_path: board_path(board) }
            render json: serialize_as_json(board).merge(extra_json)
          else
            render json: board.errors, status: :unprocessable_entity
          end
        end
      end
    end

    def update
      service = ::Boards::UpdateService.new(parent, current_user, board_params)

      service.execute(board)

      respond_to do |format|
        format.json do
          if board.valid?
            extra_json = { board_path: board_path(board) }
            render json: serialize_as_json(board).merge(extra_json)
          else
            render json: board.errors, status: :unprocessable_entity
          end
        end
      end
    end

    def destroy
      service = ::Boards::DestroyService.new(parent, current_user)
      service.execute(board)

      respond_to do |format|
        format.json { head :ok }
        format.html { redirect_to boards_path, status: :found }
      end
    end

    private

    def redirect_to_recent_board
      return if request.format.json? || !parent.multiple_issue_boards_available?

      if recently_visited = ::Boards::Visits::LatestService.new(parent, current_user).execute
        redirect_to board_path(recently_visited.board)
      end
    end

    def authorize_create_board!
      if group?
        check_multiple_group_issue_boards_available!
      else
        check_multiple_project_issue_boards_available!
      end
    end

    def authorize_admin_board!
      return render_404 unless can?(current_user, :admin_board, parent)
    end
  end
end
