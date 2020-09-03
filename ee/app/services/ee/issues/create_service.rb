# frozen_string_literal: true

module EE
  module Issues
    module CreateService
      extend ::Gitlab::Utils::Override

      override :before_create
      def before_create(issue)
        handle_epic(issue)

        super
      end

      def handle_epic(issue)
        issue.confidential = true if epic_param&.confidential

        super
      end
    end
  end
end
