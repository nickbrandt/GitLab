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
        "Added #{target_name}#{@details[:as] ? " as #{@details[:as]}" : ''}"
      when :remove
        "Removed #{target_name}"
      when :failed_login
        "Failed to login with #{oauth_label} authentication"
      when :custom_message
        detail_value
      else
        text_for_change(target_name)
      end
    end

    def text_for_change(value)
      changed = ["Changed #{value}"]

      changed << "from #{@details[:from]}" if @details[:from]
      changed << "to #{@details[:to]}" if @details[:to]

      changed.join(' ')
    end

    def target_name
      @details[:target_type] == 'Operations::FeatureFlag' ? detail_value : target_name_with_space
    end

    def target_name_with_space
      detail_value.tr('_', ' ')
    end

    def detail_value
      @details.values.first
    end

    def oauth_label
      Gitlab::Auth::OAuth::Provider.label_for(detail_value).upcase
    end
  end
end
