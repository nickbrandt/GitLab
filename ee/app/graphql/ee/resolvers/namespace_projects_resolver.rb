# frozen_string_literal: true

module EE
  module Resolvers
    module NamespaceProjectsResolver
      extend ActiveSupport::Concern

      prepended do
        argument :has_code_coverage, GraphQL::BOOLEAN_TYPE,
                 required: false,
                 default_value: false,
                 description: 'Returns only the projects which have code coverage.'

        argument :has_vulnerabilities, GraphQL::BOOLEAN_TYPE,
                 required: false,
                 default_value: false,
                 description: 'Returns only the projects which have vulnerabilities.'
      end

      def resolve(include_subgroups:, search:, sort:, ids:, has_vulnerabilities: false, has_code_coverage: false)
        projects = super(include_subgroups: include_subgroups, search: search, sort: sort, ids: ids)
        projects = projects.has_vulnerabilities if has_vulnerabilities
        projects = projects.with_code_coverage if has_code_coverage
        projects = projects.order_by_total_repository_size_excess_desc(namespace.actual_size_limit) if sort == :storage
        projects
      end
    end
  end
end
