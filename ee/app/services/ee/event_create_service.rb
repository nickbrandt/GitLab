# frozen_string_literal: true

module EE
  module EventCreateService
    def open_epic(epic, current_user)
      create_record_event(epic, current_user, ::Event::CREATED)
    end

    def close_epic(epic, current_user)
      create_record_event(epic, current_user, ::Event::CLOSED)
    end

    def reopen_epic(epic, current_user)
      create_record_event(epic, current_user, ::Event::REOPENED)
    end

    def approve_mr(merge_request, current_user)
      create_record_event(merge_request, current_user, ::Event::APPROVED)
    end
  end
end
