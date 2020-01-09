# frozen_string_literal: true

module API
  module Analytics
    class CodeReviewAnalytics < Grape::API
      include PaginationParams

      helpers do
        def project
          @project ||= find_project!(params[:project_id])
        end
      end

      before do
        not_found! unless Feature.enabled?(:code_review_analytics)
      end

      resource :analytics do
        desc 'List code review information about project' do
        end
        params do
          requires :project_id, type: Integer, desc: 'Project ID'
          use :pagination
        end
        get 'code_review' do
          authorize! :read_code_review_analytics, project
          not_found! unless project.feature_available?(:code_review_analytics, current_user)

          [
            {
              title: 'ABC',
              iid: 12345,
              web_url: 'https://gitlab.com/gitlab-org/gitlab/merge_requests/38062',
              created_at: Time.now,
              milestone: { id: 123, iid: 1234, title: '11.1', web_url: 'https://gitlab.com/gitlab-org/gitlab/merge_requests?milestone_title=12.7', due_date: Time.now },
              review_time: 64,
              author: { id: 123, username: 'foo', name: 'bar', web_url: 'https://gitlab.com/username', avatar_url: 'URL' },
              approved_by: [{ id: 123, username: 'foo', name: 'bar', web_url: 'https://gitlab.com/username', avatar_url: 'URL' }],
              notes_count: 21,
              diff_stats: { additions: 504, deletions: 10, total: 514, commits_count: 7 }
            }
          ].as_json
        end
      end
    end
  end
end
