# frozen_string_literal: true

module DraftNotes
  class BaseService
    attr_accessor :merge_request, :current_user, :params

    def initialize(merge_request, current_user, params = nil)
      @merge_request, @current_user, @params = merge_request, current_user, params.dup
    end

    private

    def draft_notes
      @draft_notes ||= merge_request.draft_notes.authored_by(current_user)
    end

    def project
      merge_request.target_project
    end
  end
end
