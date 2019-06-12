# frozen_string_literal: true
module EE
  module RunnersHelper
    def purchase_shared_runner_minutes_link(user, project)
      if ::Gitlab.com? && can?(user, :admin_project, project)
        link_to(_("Click here"), EE::SUBSCRIPTIONS_PLANS_URL, target: '_blank', rel: 'noopener') + s_("Pipelines| to purchase more minutes.")
      else
        s_("Pipelines|Pipelines will not run anymore on shared Runners.")
      end
    end
  end
end
