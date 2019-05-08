# frozen_string_literal: true

module Security
  class DependenciesFinder
    attr_accessor :params
    attr_reader :project

    SORT_BY_VALUES = %w(name type).freeze
    SORT_VALUES = %w(asc desc).freeze

    # @param project [Project]
    # @param [Hash] params to sort dependencies
    # @option params ['asc', 'desc'] :sort ('asc') Order
    # @option params ['name', 'type'] :sort_by ('name') Field to sort
    def initialize(project:, params: {})
      @project = project
      @params = params
    end

    # @return [Array<Hash>] collection of found dependencies
    def execute
      collection = init_collection
      collection = sort(collection)
      collection
    end

    private

    def init_collection
      array = []
      100.times { array << mock }
      array
    end

    def fake_name
      (0..16).map { ('a'..'z').to_a[rand 26] }.join
    end

    def mock
      {
        name: fake_name,
        type: %w(gem npm module).sample,
        location: {
          blob_path: 'gitlab-org/gitlab-ee/blob/master/Gemfile.lock#L1248'
        },
        version: '5.4.1',
        requirements: [
            '~>5.4.1'
          ]
      }
    end

    def sort(collection)
      if @params[:sort_by] == 'type'
        collection.sort_by! { |a| a[:type] }
      else
        collection.sort_by! { |a| a[:name] }
      end

      collection.reverse! if @params[:sort] == 'desc'

      collection
    end
  end
end
