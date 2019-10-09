# frozen_string_literal: true

module Banzai
  module ReferenceParser
    class MentionedUsersByProjectParser < ProjectParser
      PROJECT_ATTR = 'data-project'
      self.reference_type = :user

      def references_relation
        Project
      end

      def self.data_attribute
        @data_attribute ||= PROJECT_ATTR
      end
    end
  end
end
