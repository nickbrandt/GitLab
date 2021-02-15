# frozen_string_literal: true

module EE
  module Gitlab
    module Usage
      module Metrics
        extend ActiveSupport::Concern

        class_methods do
          extend ::Gitlab::Utils::Override

          override :paths
          def paths
            @ee_paths ||= [Rails.root.join('ee', 'config', 'metrics', '**', '*.yml')] + super
          end
        end
      end
    end
  end
end
