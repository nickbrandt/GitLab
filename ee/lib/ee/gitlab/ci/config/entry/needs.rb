# frozen_string_literal: true

module EE
  module Gitlab
    module Ci
      module Config
        module Entry
          module Needs
            extend ActiveSupport::Concern

            class_methods do
              extend ::Gitlab::Utils::Override

              override :all_types
              def all_types
                super + [Entry::Need::Bridge]
              end
            end
          end
        end
      end
    end
  end
end
