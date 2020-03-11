# frozen_string_literal: true

module EE
  module UserTypeEnums
    extend ActiveSupport::Concern

    class_methods do
      extend ::Gitlab::Utils::Override

      override :types
      def types
        super.merge(service_user: 4)
      end

      override :bots
      def bots
        super.merge(support_bot: 1, visual_review_bot: 3)
      end
    end
  end
end
