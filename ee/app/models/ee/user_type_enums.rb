# frozen_string_literal: true

module EE
  module UserTypeEnums
    extend ActiveSupport::Concern

    class_methods do
      extend ::Gitlab::Utils::Override

      override :types
      def types
        # When adding a new key, please ensure you are not conflicting
        # with EE-only keys in app/models/user_type_enums.rb
        # or app/models/user_bot_type_enums.rb
        super.merge(ServiceUser: 4)
      end

      override :bots
      def bots
        super.merge(SupportBot: 1, VisualReviewBot: 3)
      end
    end
  end
end
