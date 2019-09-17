# frozen_string_literal: true

module Gitlab
  module Ci
    module Status
      class Composite
        include Gitlab::Utils::StrongMemoize

        attr_reader :warnings

        # This class accepts an array of arrays
        # The `status_key` and `allow_failure_key` define an index
        # or key in each entry
        def initialize(all_statuses, status_key:, allow_failure_key:)
          raise ArgumentError, "all_statuses needs to be an Array" unless all_statuses.is_a?(Array)

          @count = 0
          @warnings = 0
          @status_set = Set.new
          @status_key = status_key
          @allow_failure_key = allow_failure_key

          build_status_set(all_statuses)
        end

        # The status calculation is order dependent,
        # 1. In some cases we assume that that status is exact
        #    if the we only have given statues,
        # 2. In other cases we assume that status is of that type
        #    based on what statuses are no longer valid based on the
        #    data set that we have
        def status
          strong_memoize(:status) do
            next if @count.zero?

            if none? || only_of?(:skipped)
              warnings? ? 'success' : 'skipped'
            elsif only_of?(:success, :skipped)
              'success'
            elsif only_of?(:created)
              'created'
            elsif only_of?(:preparing)
              'preparing'
            elsif only_of?(:canceled, :success, :skipped)
              'canceled'
            elsif only_of?(:pending, :created, :skipped)
              'pending'
            elsif any_of?(:running, :pending)
              'running'
            elsif any_of?(:manual)
              'manual'
            elsif any_of?(:scheduled)
              'scheduled'
            elsif any_of?(:preparing)
              'preparing'
            elsif any_of?(:created)
              'running'
            else
              'failed'
            end
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
            status = Array(status)

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
