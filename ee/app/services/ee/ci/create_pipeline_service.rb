# frozen_string_literal: true

module EE
  module Ci
    module CreatePipelineService
      extend ::Gitlab::Utils::Override

      override :extra_options
      def extra_options(mirror_update: false)
        {
          allow_mirror_update: mirror_update,
          chat_data: params[:chat_data]
        }
      end
    end
  end
end
