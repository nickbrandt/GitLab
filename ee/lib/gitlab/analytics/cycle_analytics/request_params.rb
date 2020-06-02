# frozen_string_literal: true

module Gitlab
  module Analytics
    module CycleAnalytics
      class RequestParams
        include ActiveModel::Model
        include ActiveModel::Validations
        include ActiveModel::Attributes

        MAX_RANGE_DAYS = 180.days.freeze
        DEFAULT_DATE_RANGE = 29.days # 30 including Date.today

        STRONG_PARAMS_DEFINITION = [
          :created_before,
          :created_after,
          :author_username,
          :milestone_title,
          label_name: [].freeze,
          assignee_username: [].freeze,
          project_ids: [].freeze
        ].freeze

        attr_writer :project_ids

        attribute :created_after, :datetime
        attribute :created_before, :datetime

        attr_accessor :group, :author_username, :milestone_title, :label_name, :assignee_username, :current_user

        validates :created_after, presence: true
        validates :created_before, presence: true
        validates :current_user, presence: true

        validate :validate_created_before
        validate :validate_date_range

        def initialize(params = {})
          super(params)

          self.created_before = (self.created_before || Time.now).at_end_of_day
          self.created_after  = (created_after || default_created_after).at_beginning_of_day
        end

        def project_ids
          Array(@project_ids)
        end

        def to_data_attributes
          {}.tap do |attrs|
            attrs[:group] = group_data_attributes if group
            attrs[:created_after] = created_after.to_date.iso8601
            attrs[:created_before] = created_before.to_date.iso8601
            attrs[:projects] = group_projects(project_ids) if group && project_ids.any?
          end
        end

        def to_data_collector_params
          {
            current_user: current_user,
            created_after: created_after,
            created_before: created_before,
            project_ids: project_ids,
            assignee_username: assignee_username,
            author_username: author_username,
            milestone_title: milestone_title,
            label_name: label_name
          }
        end

        private

        def group_data_attributes
          {
            id: group.id,
            name: group.name,
            parent_id: group.parent_id,
            full_path: group.full_path,
            avatar_url: group.avatar_url
          }
        end

        def group_projects(project_ids)
          GroupProjectsFinder.new(
            group: group,
            current_user: current_user,
            options: { include_subgroups: true },
            project_ids_relation: project_ids
          )
          .execute
          .with_route
          .map { |project| project_data_attributes(project) }
          .to_json
        end

        def project_data_attributes(project)
          {
            id: project.id,
            name: project.name,
            path_with_namespace: project.path_with_namespace,
            avatar_url: project.avatar_url
          }
        end

        def validate_created_before
          return if created_after.nil? || created_before.nil?

          errors.add(:created_before, :invalid) if created_after > created_before
        end

        def validate_date_range
          return if created_after.nil? || created_before.nil?

          if (created_before - created_after) > MAX_RANGE_DAYS
            errors.add(:created_after, s_('CycleAnalytics|The given date range is larger than 180 days'))
          end
        end

        def default_created_after
          if created_before
            (created_before - DEFAULT_DATE_RANGE)
          else
            DEFAULT_DATE_RANGE.ago
          end
        end
      end
    end
  end
end
