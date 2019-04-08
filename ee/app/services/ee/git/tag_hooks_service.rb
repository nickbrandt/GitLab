# frozen_string_literal: true

module EE
  module Git
    module TagHooksService
      extend ::Gitlab::Utils::Override

      private

      override :pipeline_options
      def pipeline_options
        { mirror_update: params[:mirror_update] }
      end
    end
  end
end
