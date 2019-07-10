# frozen_string_literal: true

module Audit
  class Details
    ACTIONS = %i[add remove failed_login change custom_message].freeze

    def self.humanize(*args)
      new(*args).humanize
    end

    def initialize(details)
      @details = details
    end

    def humanize
      if @details[:with]
        "Signed in with #{@details[:with].upcase} authentication"
      else
        action_text
      end
    end

    private

    def action_text
      action = @details.slice(*ACTIONS)

      case action.keys.first
      when :add
        "Added #{target_type_value}#{@details[:as] ? " as #{@details[:as]}" : ''}"
      when :remove
        "Removed #{target_type_value}"
      when :failed_login
        "Failed to login with #{Gitlab::Auth::OAuth::Provider.label_for(target_type_value).upcase} authentication"
      when :custom_message
        target_type_value
      else
        text_for_change(target_type_value)
      end
    end

    def text_for_change(value)
      changed = ["Changed #{value}"]

      changed << "from #{@details[:from]}" if @details[:from]
      changed << "to #{@details[:to]}" if @details[:to]

      changed.join(' ')
    end

    def target_type_value
      target_type = @details[:target_type]
      val = @details.values.first
      target_type == 'Operations::FeatureFlag' ? val : val.tr('_', ' ')
    end
  end
end
