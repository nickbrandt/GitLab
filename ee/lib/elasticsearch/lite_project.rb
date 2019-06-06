# frozen_string_literal: true

module Elasticsearch
  class LiteProject
    include Gitlab::Utils::StrongMemoize

    attr_accessor :id, :name, :path, :description, :namespace_id, :create_at, :updated_at, :archived,
                  :visibility_level, :last_activity_at, :name_with_namespace, :path_with_namespace,
                  :issues_access_level, :merge_requests_access_level, :snippets_access_level, :wiki_access_level,
                  :repository_access_level
    attr_accessor :pipeline_status, :commit, :creator

    alias_attribute :last_activity_date, :last_activity_at

    def initialize(raw_project_hash)
      raw_project_hash.each do |key, value|
        value = value.to_datetime if key =~ /_at$/
        self.instance_variable_set(:"@#{key}", value)
      end
    end

    # only used for routing and results display, so we trick Rails here
    def namespace
      # can't use an OpenStruct because to_param is a defined method on it
      Struct.new(:to_param, :human_name).new(
        path_with_namespace.sub(/\/#{path}$/, ''),
        name_with_namespace.sub(/\s+\/\s+#{name}$/, '')
      )
    end

    def route
      # Creates an object that has a `cache_key` attribute set to nil
      Struct.new(:cache_key).new(nil)
    end

    def pending_delete?
      false
    end

    def cache_key
      "lite_projects/#{id}-#{updated_at.utc.to_s(:number)}"
    end

    def to_param
      path&.to_s
    end

    def model_name
      OpenStruct.new(param_key: 'project')
    end

    def banzai_render_context(field)
      return unless field == :description

      { pipeline: :description, project: self }
    end

    def default_issues_tracker?
      true
    end

    # rubocop: disable CodeReuse/ActiveRecord
    # This method is required by the OpenMergeRequestsCountService
    def merge_requests
      strong_memoize(:merge_requests) do
        MergeRequest.opened.where(project_id: self.id)
      end
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def forks_count
      Projects::ForksCountService.new(self).count
    end

    def open_issues_count(current_user = nil)
      Projects::OpenIssuesCountService.new(self, current_user).count
    end

    def open_merge_requests_count
      Projects::OpenMergeRequestsCountService.new(self).count
    end
  end
end
