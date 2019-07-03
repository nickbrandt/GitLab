# frozen_string_literal: true

module EE
  module ChatMessage
    module MergeMessage
      extend ActiveSupport::Concern
      extend ::Gitlab::Utils::Override

      prepended do
        attr_reader :action
      end

      def initialize(params)
        super

        @action = params[:object_attributes][:action]
      end

      override :state_or_action_text
      def state_or_action_text
        case action
        when 'approved', 'unapproved'
          action
        when 'approval'
          'added their approval to'
        when 'unapproval'
          'removed their approval from'
        else
          super
        end
      end
    end
  end
end
