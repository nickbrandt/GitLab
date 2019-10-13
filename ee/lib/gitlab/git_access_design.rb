# frozen_string_literal: true

module Gitlab
  class GitAccessDesign < GitAccess
    def check(cmd, _changes)
      unless geo?
        check_protocol!
        check_can_create_design!
      end

      success_result(cmd)
    end

    private

    def check_protocol!
      if protocol != 'web'
        raise ::Gitlab::GitAccess::UnauthorizedError, "Designs are only accessible using the web interface"
      end
    end

    def check_can_create_design!
      unless user&.can?(:create_design, project)
        raise ::Gitlab::GitAccess::UnauthorizedError, "You are not allowed to manage designs of this project"
      end
    end
  end
end
