# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module External
        class Reader
          module ObjectWithLocation
            attr_accessor :location_filename, :location_line, :location_column

            # https://github.com/rails/rails/blob/6-0-stable/activesupport/lib/active_support/hash_with_indifferent_access.rb#L253-L257
            def dup
              if self.is_a?(ActiveSupport::HashWithIndifferentAccess)
                self.class.new(self).tap do |new_hash|
                  set_defaults(new_hash)
                end
              else
                super.extend(ObjectWithLocation).tap do |object|
                  object.location_filename = self.location_filename
                  object.location_line = self.location_line
                  object.location_column = self.location_column
                end
              end
            end
          end
        end
      end
    end
  end
end
