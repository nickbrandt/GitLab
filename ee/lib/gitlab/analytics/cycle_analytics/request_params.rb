# frozen_string_literal: true

module Gitlab
  module Analytics
    module CycleAnalytics
      class RequestParams
        include ActiveModel::Model
        include ActiveModel::Validations
        include ActiveModel::Attributes

        MAX_RANGE_DAYS = 180.days.freeze
        DEFAULT_DATE_RANGE = 30.days

        attr_writer :project_ids

        attribute :created_after, :date
        attribute :created_before, :date

        attr_accessor :group

        attr_reader :current_user

        validates :created_after, presence: true
        validates :created_before, presence: true

        validate :validate_created_before
        validate :validate_date_range

        def initialize(params = {}, current_user:)
          params[:created_before] ||= Date.today.at_end_of_day
          params[:created_after] ||= default_created_after(params[:created_before])

          @current_user = current_user

          super(params)
        end

        def project_ids
          Array(@project_ids)
        end

        def to_data_attributes
          {}.tap do |attrs|
            attrs[:group] = group_data_attributes if group
            attrs[:created_after] = created_after.iso8601
            attrs[:created_before] = created_before.iso8601
            attrs[:projects] = group_projects(project_ids) if group && project_ids.any?
          end
        end

        private

        def group_data_attributes
          {
            id: group.id,
            name: group.name,
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

          if (created_before - created_after).days > MAX_RANGE_DAYS
            errors.add(:created_after, s_('CycleAnalytics|The given date range is larger than 180 days'))
          end
        end

        def default_created_after(start_date = nil)
          if start_date
            (start_date.to_time - DEFAULT_DATE_RANGE).to_datetime
          else
            DEFAULT_DATE_RANGE.ago.utc.beginning_of_day
          end
        end
      end
    end
  end
end
