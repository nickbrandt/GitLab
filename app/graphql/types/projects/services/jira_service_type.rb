# frozen_string_literal: true

module Types
  module Projects
    module Services
      class JiraServiceType < BaseObject
        graphql_name 'JiraService'

        implements(Types::Projects::ServiceType)

        authorize :admin_project

        field :all_projects,
              [Types::Projects::Services::JiraProjectType],
              null: true,
              connection: false,
              description: 'List of all Jira projects fetched through Jira REST API. Latest Jira Server API version ([8.9.0](https://docs.atlassian.com/software/jira/docs/api/REST/8.9.0/)) compatible.'

        field :projects,
              Types::Projects::Services::JiraProjectType.connection_type,
              null: true,
              connection: false,
              extensions: [Gitlab::Graphql::Extensions::ExternallyPaginatedArrayExtension],
              description: 'List of Jira projects fetched through Jira REST API',
              resolver: Resolvers::Projects::JiraProjectsResolver

        def all_projects
          raise Gitlab::Graphql::Errors::BaseError, _('Jira service not configured.') unless object&.active?
          raise Gitlab::Graphql::Errors::BaseError, _('Unable to connect to the Jira instance. Please check your Jira integration configuration.') unless object.test(nil)[:success]

          object.client.Project.all
        end
      end
    end
  end
end
