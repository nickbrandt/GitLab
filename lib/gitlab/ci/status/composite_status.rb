# frozen_string_literal: true

module Gitlab
  module Ci
    module Status
      class CompositeStatus
        def initialize(all_statuses)
          @status_set = build_status_set(all_statuses)
        end

        def status
          case
          when only?(:skipped, :warning)
            :success
          when only?(:skipped)
            :skipped
          when only?(:success)
            :skipped
          when only?(:created)
            :created
          when only?(:preparing)
            :preparing
          when only?(:success, :skipped)
            :success
          when only?(:success, :skipped, :canceled)
            :canceled
          when only?(:created, :skipped, :pending)
            :pending
          when include?(:running, :pending)
            :running
          when include?(:manual)
            :manual
          when include?(:scheduled)
            :scheduled
          when include?(:preparing)
            :preparing
          when include?(:created)
            :running
          else
            :failed
          end
        end

        def warnings?
          include?(:warning)
        end

        private

        def include?(*names)
          names.any? { |name| @status_set.include?(name) }
        end

        def only?(*names)
          matching = names.count { |name| @status_set.include?(name) } == @status_set.size
        end

        def build_status_set(all_statuses)
          status_set = Set.new

          all_statuses.each do |status|
            if status[:allow_failure] && HasStatus::WARNING_STATUSES.include?(status[:status])
              status_set.add(:warning)
            else
              status_set.add(status[:status].to_sym)
            end
          end

          status_set
        end
      end
    end
  end
end
