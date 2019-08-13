# frozen_string_literal: true

module Gitlab
  module Ci
    module Status
      class GroupedStatuses
        def initialize(subject, *keys)
          @subject = subject
          @keys = keys
        end

        def one(**query)
          validate_keys!(query.keys)

          item_hash = find_one(data_hash, query)
          status_for_key(query, item_hash) if item_hash
        end

        def group(*keys)
          validate_keys!(keys)

          grouped_statuses(data_hash, keys)
        end

        private

        def validate_keys!(keys)
          missing_keys = @keys - keys
          if missing_keys.present?
            raise ArgumentError, "the keys '#{missing_keys.join(',')} are not subset of #{@keys.join(',')}"
          end
        end

        def data_hash
          @data_hash ||= hash_from_relation(@subject, @keys)
        end

        def hash_from_relation(subject, keys)
          columns = keys.dup
          columns << :status

          # we request allow_failure when
          # we don't have column_names, or such column does exist
          columns << :allow_failure if !subject.respond_to?(:column_names) || subject.column_names.include?('allow_failure')
    
          subject
            .pluck(*columns)
            .map { |attrs| columns.zip(attrs).to_h }
        end

        def find_one(subject, query)
          subject.select do |attrs|
            query.all? do |key, value|
              attrs[key] == value
            end
          end.presence
        end

        def grouped_statuses(subject, keys)
          subject
            .group_by { |attrs| attrs.slice(*keys) }
            .map { |key, all_attrs| status_for_key(key, all_attrs) }
        end

        def status_for_key(key, all_attrs)
          composite_status = Gitlab::Ci::Status::CompositeStatus.new(all_attrs)

          key.merge(
            status: composite_status.status.to_s,
            warnings: composite_status.warnings?)
        end
      end
    end
  end
end
