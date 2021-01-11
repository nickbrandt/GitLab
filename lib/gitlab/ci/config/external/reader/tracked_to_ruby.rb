# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module External
        class Reader
          class TrackedToRuby < Psych::Visitors::ToRuby
            attr_accessor :location_filename

            def visit_Psych_Nodes_Scalar(object) # rubocop:disable Naming/MethodName
              value = super
              return value unless value.class.in?([String, Symbol])

              value.to_s.extend(Reader::ObjectWithLocation).tap do |value|
                value.location_filename = location_filename
                value.location_line = object.start_line..object.end_line
                value.location_column = object.start_column..object.end_column
              end
            end
          end
        end
      end
    end
  end
end
