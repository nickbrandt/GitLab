# frozen_string_literal: true

module EE
  module SystemCheck
    module RakeTask
      module GitlabTask
        extend ActiveSupport::Concern

        class_methods do
          extend ::Gitlab::Utils::Override

          override :subtasks
          def subtasks
            existing = super

            existing << ::SystemCheck::RakeTask::GeoTask if ::Gitlab::Geo.enabled?

            existing
          end
        end
      end
    end
  end
end
