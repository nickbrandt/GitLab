# frozen_string_literal: true

module MultiUserSession
  extend ActiveSupport::Concern

  class_methods do
    include Gitlab::Utils::StrongMemoize

    def authorized_users
      strong_memoize(:authorized_users) do
        User.where(id: Gitlab::WardenSession.authorized_user_ids)
      end
    end
  end
end
