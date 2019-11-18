# frozen_string_literal: true

module EE
  module Notes
    module CreateService
      extend ::Gitlab::Utils::Override

      override :quick_action_options
      def quick_action_options
        super.merge(review_id: params[:review_id])
      end
    end
  end
end
