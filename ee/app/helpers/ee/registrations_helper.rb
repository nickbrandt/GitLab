# frozen_string_literal: true

module EE
  module RegistrationsHelper
    include ::Gitlab::Utils::StrongMemoize

    def in_subscription_flow?
      redirect_path == new_subscriptions_path
    end

    def in_trial_flow?
      redirect_path == new_trial_path
    end

    def in_invitation_flow?
      redirect_path&.starts_with?('/-/invites/')
    end

    def setup_for_company_label_text
      if in_subscription_flow?
        _('Who will be using this GitLab subscription?')
      elsif in_trial_flow?
        _('Who will be using this GitLab trial?')
      else
        _('Who will be using GitLab?')
      end
    end

    private

    def redirect_path
      strong_memoize(:redirect_path) do
        redirect_to = session['user_return_to']
        URI.parse(redirect_to).path if redirect_to
      end
    end
  end
end
