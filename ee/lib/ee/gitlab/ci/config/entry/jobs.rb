# frozen_string_literal: true

module EE
  module Gitlab
    module Ci
      module Config
        module Entry
          module Jobs
            extend ActiveSupport::Concern

            prepended do
              EE_TYPES = const_get(:TYPES, false) + [::EE::Gitlab::Ci::Config::Entry::Bridge]
            end

            class_methods do
              extend ::Gitlab::Utils::Override

              override :all_types
              def all_types
                EE_TYPES
              end
            end
          end
        end
      end
    end
  end
end
