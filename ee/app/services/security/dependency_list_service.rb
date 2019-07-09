# frozen_string_literal: true

module Security
  class DependencyListService
    SORT_BY_VALUES = %w(name packager).freeze
    SORT_VALUES = %w(asc desc).freeze
    FILTER_PACKAGE_MANAGERS_VALUES = %w(bundler yarn npm maven composer pip).freeze

    # @param pipeline [Ci::Pipeline]
    # @param [Hash] params to sort and filter dependencies
    # @option params ['asc', 'desc'] :sort ('asc') Order
    # @option params ['name', 'packager'] :sort_by ('name') Field to sort
    # @option params ['bundler', 'yarn', 'npm', 'maven', 'composer', 'pip'] :package_manager ('bundler') Field to filter
    def initialize(pipeline:, params: {})
      @pipeline = pipeline
      @params = params
    end

    # @return [Array<Hash>] collection of found dependencies
    def execute
      collection = init_collection
      collection = filter(collection)
      collection = sort(collection)
      collection
    end

    private

    attr_accessor :params, :pipeline

    def init_collection
      pipeline.dependency_list_report.dependencies
    end

    def filter(collection)
      return collection unless params[:package_manager]

      collection.select do |dependency|
        params[:package_manager].include?(dependency[:package_manager])
      end
    end

    def sort(collection)
      if params[:sort_by] == 'packager'
        collection.sort_by! { |a| a[:packager] }
      else
        collection.sort_by! { |a| a[:name] }
      end

      collection.reverse! if params[:sort] == 'desc'

      collection
    end
  end
end
