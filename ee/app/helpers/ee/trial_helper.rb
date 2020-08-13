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
        'Groups' => trial_group_namespaces.map { |n| [n.name, n.id] },
        'Users' => trial_user_namespaces.map { |n| [n.name, n.id] }
      }

      grouped_options_for_select(grouped_options, selected, prompt: _('Please select'))
    end

    def trial_group_namespaces
      current_user.manageable_groups_eligible_for_trial
    end

    def trial_user_namespaces
      user_namespace = current_user.namespace
      user_namespace.eligible_for_trial? ? [user_namespace] : []
    end

    def show_trial_errors?(namespace, service_result)
      namespace&.invalid? || (service_result && !service_result[:success])
    end

    def trial_errors(namespace, service_result)
      namespace&.errors&.full_messages&.to_sentence&.presence || service_result&.dig(:errors)&.presence
    end
  end
end
