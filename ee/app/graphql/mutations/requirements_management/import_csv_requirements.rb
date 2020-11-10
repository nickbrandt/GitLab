# frozen_string_literal: true

module Mutations
  module RequirementsManagement
    class ImportCsvRequirements < BaseMutation
      include ResolvesProject

      graphql_name 'RequirementsImportCsv'

      argument :project_path, GraphQL::ID_TYPE,
               required: true,
               description: 'Full project path the requirements are associated with'

      argument :file, ApolloUploadServer::Upload,
               required: true,
               description: 'The CSV file to upload'

      field :imported_count, GraphQL::INT_TYPE, null: true,
            description: 'Number of successfully imported requirements'

      authorize :create_requirement

      def resolve(args)
        project_path = args.delete(:project_path)
        project = authorized_find!(full_path: project_path)

        if uploader = UploadService.new(project, args[:file]).execute
          results = ::RequirementsManagement::ImportCsvService
                      .new(current_user, project, uploader.upload.retrieve_uploader)
                      .execute

          parse_results(results)
        else
          { imported_count: 0, errors: ['File upload error.'] }
        end
      end

      private

      def find_object(full_path:)
        resolve_project(full_path: full_path)
      end

      def parse_results(results)
        error_messages =
          if results[:parse_error]
            ['Error parsing CSV file. Please make sure it has the correct format.']
          elsif results[:error_lines].present?
            ["Errors found on line #{'number'.pluralize(results[:error_lines].size)}: #{results[:error_lines].join(', ')}."]
          else
            []
          end

        { imported_count: results[:success], errors: error_messages }
      end
    end
  end
end
