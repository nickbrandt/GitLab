# frozen_string_literal: true

module Gitlab
  module Ci
    module Status
      class CompositeStatus
        attr_reader :warnings

        def initialize(all_statuses)
          @warnings = 0
          @status_set = Set.new

          build_status_set(all_statuses)
        end

        def status
          case
          when none?
            :skipped
          when only_of?(:skipped)
            warnings? ? :success : :skipped
          when only_of?(:success, :skipped)
            :success
          when only_of?(:created)
            :created
          when only_of?(:preparing)
            :preparing
          when only_of?(:success, :skipped, :canceled)
            :canceled
          when only_of?(:created, :skipped, :pending)
            :pending
          when any_of?(:running, :pending)
            :running
          when any_of?(:manual)
            :manual
          when any_of?(:scheduled)
            :scheduled
          when any_of?(:preparing)
            :preparing
          when any_of?(:created)
            :running
          else
            :failed
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
            if status[:allow_failure] && HasStatus::WARNING_STATUSES.include?(status[:status])
              @warnings += 1
            else
              @status_set.add(status[:status].to_sym)
            end
          end
        end
      end
    end
  end
end
