# frozen_string_literal: true

module Gitlab
  module Ci
    module Status
      class Composite
        attr_reader :warnings

        # This class accepts an array of arrays or array of hashes
        # The `status_key` and `allow_failure_key` define an index
        # or key in each entry
        def initialize(all_statuses, status_key:, allow_failure_key:)
          @count = 0
          @warnings = 0
          @status_set = Set.new
          @status_key = status_key
          @allow_failure_key = allow_failure_key

          build_status_set(all_statuses)
        end

        def status
          case
          when @count.zero?
            nil
          when none? || only_of?(:skipped)
            warnings? ? 'success' : 'skipped'
          when only_of?(:success, :skipped)
            'success'
          when only_of?(:created)
            'created'
          when only_of?(:preparing)
            'preparing'
          when only_of?(:success, :skipped, :canceled)
            'canceled'
          when only_of?(:created, :skipped, :pending)
            'pending'
          when any_of?(:running, :pending)
            'running'
          when any_of?(:manual)
            'manual'
          when any_of?(:scheduled)
            'scheduled'
          when any_of?(:preparing)
            'preparing'
          when any_of?(:created)
            'running'
          else
            'failed'
          end
        end

        def warnings?
          @warnings > 0
        end

        private

        def none?
          @status_set.empty?
        end

        def any_of?(*names)
          names.any? { |name| @status_set.include?(name) }
        end

        def only_of?(*names)
          matching = names.count { |name| @status_set.include?(name) }
          matching == @status_set.size
        end

        def build_status_set(all_statuses)
          all_statuses.each do |status|
            @count += 1
            @warnings += 1 if count_as_warning?(status)
            next if exclude_from_calculation?(status)

            @status_set.add(status[@status_key].to_sym)
          end
        end

        def count_as_warning?(status)
          @allow_failure_key &&
            status[@allow_failure_key] &&
            HasStatus::PASSED_WITH_WARNINGS_STATUSES.include?(status[@status_key])
        end

        def exclude_from_calculation?(status)
          @allow_failure_key &&
            status[@allow_failure_key] &&
            HasStatus::EXCLUDE_IGNORED_STATUSES.include?(status[@status_key])
        end
      end
    end
  end
end
