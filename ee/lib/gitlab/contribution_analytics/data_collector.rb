# frozen_string_literal: true

# rubocop: disable CodeReuse/ActiveRecord

module Gitlab
  module ContributionAnalytics
    class DataCollector
      EVENT_TYPES = %i[push issues_created issues_closed merge_requests_created merge_requests_merged total_events].freeze

      attr_reader :group, :from

      def initialize(group:, from: 1.week.ago.to_date)
        @group = group
        @from = from
      end

      def push_by_author_count
        all_counts.each_with_object({}) do |((author_id, target_type, action), count), hash|
          hash[author_id] = count if target_type.nil? && action.eql?(Event::PUSHED)
        end
      end

      def issues_created_by_author_count
        all_counts.each_with_object({}) do |((author_id, target_type, action), count), hash|
          hash[author_id] = count if target_type.eql?(Issue.name) && action.eql?(Event::CREATED)
        end
      end

      def issues_closed_by_author_count
        all_counts.each_with_object({}) do |((author_id, target_type, action), count), hash|
          hash[author_id] = count if target_type.eql?(Issue.name) && action.eql?(Event::CLOSED)
        end
      end

      def merge_requests_created_by_author_count
        all_counts.each_with_object({}) do |((author_id, target_type, action), count), hash|
          hash[author_id] = count if target_type.eql?(MergeRequest.name) && action.eql?(Event::CREATED)
        end
      end

      def merge_requests_merged_by_author_count
        all_counts.each_with_object({}) do |((author_id, target_type, action), count), hash|
          hash[author_id] = count if target_type.eql?(MergeRequest.name) && action.eql?(Event::MERGED)
        end
      end

      def total_events_by_author_count
        all_counts.each_with_object({}) do |((author_id, _target_type, _action), count), hash|
          hash[author_id] ||= 0
          hash[author_id] += count
        end
      end

      def total_push_author_count
        all_counts.count { |(_, _, action), _| action.eql?(Event::PUSHED) }
      end

      def total_push_count
        all_counts.sum { |(_, _, action), count| action.eql?(Event::PUSHED) ? count : 0 }
      end

      def total_commit_count
        PushEventPayload.commit_count_for(base_query.code_push)
      end

      def total_merge_requests_created_count
        all_counts.sum { |(_, target_type, action), count| target_type.eql?(MergeRequest.name) && action.eql?(Event::CREATED) ? count : 0 }
      end

      def total_merge_requests_merged_count
        all_counts.sum { |(_, target_type, action), count| target_type.eql?(MergeRequest.name) && action.eql?(Event::MERGED) ? count : 0 }
      end

      def total_issues_created_count
        all_counts.sum { |(_, target_type, action), count| target_type.eql?(Issue.name) && action.eql?(Event::CREATED) ? count : 0 }
      end

      def total_issues_closed_count
        all_counts.sum { |(_, target_type, action), count| target_type.eql?(Issue.name) && action.eql?(Event::CLOSED) ? count : 0 }
      end

      def users
        @users ||= User
          .select(:id, :name, :username)
          .where(id: total_events_by_author_count.keys)
          .reorder(:id)
      end
      # rubocop: enable CodeReuse/ActiveRecord

      def group_member_contributions_table_data
        {
          labels: users.map(&:name),
          push: { data: count_by_user(push_by_author_count) },
          issues_closed: { data: count_by_user(issues_closed_by_author_count) },
          merge_requests_created: { data: count_by_user(merge_requests_created_by_author_count) }
        }
      end

      def totals
        @totals ||= {
          push: push_by_author_count,
          issues_created: issues_created_by_author_count,
          issues_closed: issues_closed_by_author_count,
          merge_requests_created: merge_requests_created_by_author_count,
          merge_requests_merged: merge_requests_merged_by_author_count,
          total_events: total_events_by_author_count
        }
      end

      private

      # rubocop: disable CodeReuse/ActiveRecord
      def base_query
        Event
          .where(action: ::Event::PUSHED).or(
            Event.where(target_type: [::MergeRequest.name, ::Issue.name], action: [::Event::CREATED, ::Event::CLOSED, ::Event::MERGED])
          )
          .where(Event.arel_table[:created_at].gteq(from))
          .joins(:project)
          .merge(::Project.inside_path(group.full_path))
      end
      # rubocop: enable CodeReuse/ActiveRecord

      # Format:
      # {
      #   [user1_id, target_type, action] => count,
      #   [user2_id, target_type, action] => count
      # }
      def all_counts
        @all_counts ||= Rails.cache.fetch(cache_key, expires_in: 1.minute) do
          base_query.totals_by_author_target_type_action
        end
      end

      def count_by_user(data)
        users.map { |user| data.fetch(user.id, 0) }
      end

      def cache_key
        [group, from]
      end
    end
  end
end
