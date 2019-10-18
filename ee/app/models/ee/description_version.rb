# frozen_string_literal: true

module EE
  module DescriptionVersion
    extend ActiveSupport::Concern

    prepended do
      belongs_to :epic
    end

    class_methods do
      def issuable_attrs
        (super + %i(epic)).freeze
      end
    end
  end
end
