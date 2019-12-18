# frozen_string_literal: true

module Banzai
  module FindByParent
    extend ActiveSupport::Concern

    included do
      def find_object(parent, object_identifier)
        records_per_parent[parent][object_identifier]
      end

      # A lazily-initialized two-dimensional mapping from
      # parent to record-identifier to record
      #
      # This can be used to implement `find_object(parent, id)`
      # so that they are just `records_per_parent.dig(parent, id)`
      # (see 'IssuableReferenceFilter')
      #
      # To use this mechanism, the class must implement `parent_records`.
      def records_per_parent
        @_records_per_project ||= {}

        @_records_per_project[object_class.to_s.underscore] ||= begin
          hash = Hash.new { |h, k| h[k] = {} }

          parent_per_reference.each do |path, parent|
            record_ids = references_per_parent[path]

            parent_records(parent, record_ids).each do |record|
              hash[parent][record_identifier(record)] = record
            end
          end

          hash
        end
      end

      def record_identifier(record)
        record.id
      end

      # Returns a Hash containing referenced projects grouped per their full
      # path.
      def parent_per_reference
        @per_reference ||= {}

        @per_reference[parent_type] ||= begin
          refs = Set.new

          references_per_parent.each do |ref, _|
            refs << ref
          end

          find_for_paths(refs.to_a).index_by(&:full_path)
        end
      end

      # Implement this method to make use of `records_per_parent`
      #
      # params:
      #  - parent: The parent object (usually a Project)
      #  - record_ids: array of IDs. These are usually integers, but this
      #                depends on your implementation
      # returns Enumerable<Object>
      def parent_records(parent, record_ids)
        raise NotImplementedError, 'Classes using records_per_parent must implement parent_records(parent, record_ids)'
      end
    end
  end
end
