# frozen_string_literal: true

module EE
  module UserTypeEnums
    extend ActiveSupport::Concern

    class_methods do
      extend ::Gitlab::Utils::Override

      override :types
      def types
        super.merge(ServiceUser: 4)
      end

      override :bots
      def bots
        super.merge(SupportBot: 1, VisualReviewBot: 3)
      end
    end
  end
end
