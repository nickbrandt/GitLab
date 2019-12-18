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

      # Returns a Hash containing all object references (e.g. issue IDs) per the
      # project they belong to.
      #
      # e.g.
      #   references_per_parent = {
      #     project: {
      #       'some-path/to-a-project' => Set.new(1,2,3),
      #       'some-path/to-b-project' => Set.new(1,2),
      #     }
      #    }
      def references_per_parent
        @references_per ||= {}

        @references_per[parent_type] ||= begin
          refs = Hash.new { |hash, key| hash[key] = Set.new }
          regex = Regexp.union([object_class.reference_pattern, object_class.link_reference_pattern].compact)

          nodes.each do |node|
            node.to_html.scan(regex) do
              path = if parent_type == :project
                       full_project_path($~[:namespace], $~[:project])
                     else
                       full_group_path($~[:group])
                     end

              symbol = symbol_from_match($~)
              refs[path] << self.class.parse_symbol(symbol, $~) if object_class.reference_valid?(symbol)
            end
          end

          refs
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

      def find_parent(ref)
        find_for_paths([ref]).first
      end

      # Returns projects for the given paths.
      def find_for_paths(paths)
        cache = refs_cache
        to_query = paths - cache.keys

        unless to_query.empty?
          records = relation_for_paths(to_query)

          found = []
          records.each do |record|
            ref = record.full_path
            get_or_set_cache(cache, ref) { record }
            found << ref
          end

          not_found = to_query - found
          not_found.each do |ref|
            get_or_set_cache(cache, ref) { nil }
          end
        end

        cache.slice(*paths).values.compact
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
