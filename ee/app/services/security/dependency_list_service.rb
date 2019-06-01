# frozen_string_literal: true

module Security
  class DependencyListService
    attr_accessor :params
    attr_accessor :status
    attr_reader :project

    SORT_BY_VALUES = %w(name packager).freeze
    SORT_VALUES = %w(asc desc).freeze
    SCANNING_JOB_NAME = 'dependency_scanning'.freeze

    # @param project [Project]
    # @param [Hash] params to sort dependencies
    # @option params ['asc', 'desc'] :sort ('asc') Order
    # @option params ['name', 'type'] :sort_by ('name') Field to sort
    def initialize(project:, params: {})
      @project = project
      @params = params
      @status = :ok
    end

    # @return [Array<Hash>] collection of found dependencies
    def execute
      collection = init_collection
      collection = sort(collection)
      collection
    end

    private

    def init_collection
      pipeline = project.all_pipelines.latest_successful_for(project.default_branch)
      dependencies = pipeline.dependency_list_report.dependencies
      dependencies
    end

    def sort(collection)
      if @params[:sort_by] == 'packager'
        collection.sort_by! { |a| a[:packager] }
      else
        collection.sort_by! { |a| a[:name] }
      end

      collection.reverse! if @params[:sort] == 'desc'

      collection
    end
  end
end
