# frozen_string_literal: true

module API
  class Dependencies < Grape::API
    helpers do
      def dependencies_by(params)
        pipeline = user_project.all_pipelines.latest_successful_for_ref(user_project.default_branch)

        return [] unless pipeline

        ::Security::DependencyListService.new(pipeline: pipeline, params: params).execute
      end
    end

    before do
      authenticate!
    end

    params do
      requires :id, type: String, desc: 'The ID of a project'
    end

    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      desc 'Get a list of project dependencies' do
        success ::EE::API::Entities::Dependency
      end

      params do
        optional :package_manager,
                 type: Array[String],
                 desc: "Returns dependencies belonging to specified package managers: #{::Security::DependencyListService::FILTER_PACKAGE_MANAGERS_VALUES.join(', ')}.",
                 values: ::Security::DependencyListService::FILTER_PACKAGE_MANAGERS_VALUES
      end

      get ':id/dependencies' do
        authorize! :read_dependencies, user_project

        dependencies = dependencies_by(declared_params.merge(project: user_project))

        present dependencies, with: ::EE::API::Entities::Dependency
      end
    end
  end
end
