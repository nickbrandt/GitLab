# frozen_string_literal: true

module EE
  module TrialHelper
    def company_size_options_for_select(selected = 0)
      options_for_select([
        [_('Please select'), 0],
        ['1 - 99', '1-99'],
        ['100 - 499', '100-499'],
        ['500 - 1,999', '500-1,999'],
        ['2,000 - 9,999', '2,000-9,999'],
        ['10,000 +', '10,000+']
      ], selected)
    end

    def namespace_options_for_select(selected = nil)
      grouped_options = {
        'New' => [[_('Create group'), 0]],
        'Groups' => trial_groups,
        'Users' => trial_users
      }

      grouped_options_for_select(grouped_options, selected, prompt: _('Please select'))
    end

    def trial_users
      user_namespace = current_user.namespace
      return [] if user_namespace.gitlab_subscription&.trial?

      [[user_namespace.name, user_namespace.id]]
    end

    def trial_groups
      current_user.manageable_groups_eligible_for_trial.map { |g| [g.name, g.id] }
    end

    def show_trial_errors?(namespace, service_result)
      namespace&.invalid? || (service_result && !service_result[:success])
    end

    def trial_errors(namespace, service_result)
      namespace&.errors&.full_messages&.to_sentence&.presence || service_result&.dig(:errors)&.presence
    end
  end
end
