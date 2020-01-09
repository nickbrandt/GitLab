# frozen_string_literal: true

module EE
  module UsersHelper
    def users_sentence(users, link_class: nil)
      users.map { |user| link_to(user.name, user, class: link_class) }.to_sentence.html_safe
    end

    def trials_link_url
      new_trial_registration_path
    end

    def user_badges_in_admin_section(user)
      super(user).tap do |badges|
        if user.using_license_seat?
          it_s_you_index = badges.index { |badge| badge[:text] == "It's you!" } || -1

          badges.insert(it_s_you_index, { text: s_('AdminUsers|Is using seat'), variant: 'light' })
        end
      end
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
