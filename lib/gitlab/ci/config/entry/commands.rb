# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Entry
        ##
        # Entry that represents a job script.
        #
        class Commands < ::Gitlab::Config::Entry::Node
          include ::Gitlab::Config::Entry::Validatable

          validations do
            validate do
              unless config.is_a?(String) ||
                  (config.is_a?(Array) && config.all? { |element| element.is_a?(String) || validate_array_of_strings?(element) })
                errors.add(:config, 'should be a string or an array of strings and arrays of strings')
              end
            end

            def validate_array_of_strings?(value)
              value.is_a?(Array) && value.all? { |element| element.is_a?(String) }
            end
          end

          def value
            Array(@config).flatten
          end
        end
      end
    end
  end
end
