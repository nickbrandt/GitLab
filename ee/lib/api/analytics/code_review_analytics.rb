# frozen_string_literal: true

module API
  module Analytics
    class CodeReviewAnalytics < Grape::API
      include PaginationParams

      helpers ::Gitlab::IssuableMetadata

      helpers do
        def project
          @project ||= find_project!(params[:project_id])
        end

        def finder
          @finder ||= begin
            finder_options = {
              state: 'opened',
              project_id: project.id,
              sort: 'review_time_desc',
              attempt_project_search_optimizations: true
            }

            finder_options = params.slice(*MergeRequestsFinder.valid_params).merge(finder_options)

            MergeRequestsFinder.new(current_user, finder_options)
          end
        end
      end

      resource :analytics do
        desc 'List code review information about project' do
        end
        params do
          requires :project_id, type: Integer, desc: 'Project ID'
          optional :label_name, type: Array, desc: 'Array of label names to filter by'
          optional :milestone_title, type: String, desc: 'Milestone title to filter by'
          use :pagination
        end
        get 'code_review' do
          authorize! :read_code_review_analytics, project

          merge_requests = paginate(finder.execute.with_code_review_api_entity_associations)

          present merge_requests,
                  with: EE::API::Entities::Analytics::CodeReview::MergeRequest,
                  current_user: current_user,
                  issuable_metadata: issuable_meta_data(merge_requests, 'MergeRequest', current_user)
        end
      end
    end
  end
end
