# frozen_string_literal: true

module EE
  module UserBotTypeEnums
    extend ActiveSupport::Concern

    class_methods do
      extend ::Gitlab::Utils::Override

      override :bots
      def bots
        # When adding a new key, please ensure you are not redefining a key that already exists in app/models/user_bot_types_enums.rb
        super.merge(
          support_bot: 1,
          visual_review_bot: 3
        )
      end
    end
  end
end
