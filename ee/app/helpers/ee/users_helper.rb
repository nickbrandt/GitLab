# frozen_string_literal: true

module EE
  module UsersHelper
    def users_sentence(users, link_class: nil)
      users.map { |user| link_to(user.name, user, class: link_class) }.to_sentence.html_safe
    end

    def trials_link_url
      new_trial_registration_path
    end

    private

    def trials_allowed?(user)
      return unless user
      return unless ::Gitlab.com?

      Rails.cache.fetch(['users', user.id, 'trials_allowed?'], expires_in: 10.minutes) do
        !user.has_paid_namespace? && user.any_namespace_without_trial?
      end
    end
  end
end
