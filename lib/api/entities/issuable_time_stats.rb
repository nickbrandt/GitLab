# frozen_string_literal: true

module API
  module Entities
    class IssuableTimeStats < Grape::Entity
      format_with(:time_tracking_formatter) do |time_spent|
        Gitlab::TimeTrackingFormatter.output(time_spent)
      end

      def presented
        lazy_timelogs

        super
      end

      expose :time_estimate
      expose :total_time_spent
      expose :human_time_estimate

      with_options(format_with: :time_tracking_formatter) do
        expose :total_time_spent, as: :human_total_time_spent
      end

      private

      def lazy_timelogs
        BatchLoader.for(object.id).batch(key: :timelogs, default_value: []) do |ids, loader|
          Timelog.for_merge_requests(ids).find_each do |timelog|
            loader.call(timelog.merge_request_id) { |acc| acc << timelog }
          end
        end
      end

      def total_time_spent
        lazy_timelogs.sum(&:time_spent) # rubocop:disable CodeReuse/ActiveRecord
      end
    end
  end
end
