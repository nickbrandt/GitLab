# frozen_string_literal: true

module API
  class StatusChecks < ::API::Base
    include PaginationParams

    feature_category :compliance_management

    before do
      authenticate!
      check_feature_enabled!
    end

    helpers do
      def check_feature_enabled!
        unauthorized! unless user_project.licensed_feature_available?(:external_status_checks) &&
          Feature.enabled?(:ff_external_status_checks, user_project)
      end
    end

    resource :projects, requirements: ::API::API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      segment ':id/external_status_checks' do
        desc 'Create a new external status check' do
          success ::API::Entities::ExternalStatusCheck
          detail 'This feature is gated by the :ff_external_status_checks feature flag.'
        end
        params do
          requires :name, type: String, desc: 'The name of the external status check'
          requires :external_url, type: String, desc: 'The URL to notify when MR receives new commits'
          optional :protected_branch_ids,
                   type: Array[Integer],
                   coerce_with: ::API::Validations::Types::CommaSeparatedToIntegerArray.coerce,
                   desc: 'The protected branch ids for this check'
        end
        post do
          service = ::ExternalStatusChecks::CreateService.new(
            container: user_project,
            current_user: current_user,
            params: declared_params(include_missing: false)
          ).execute

          if service.success?
            present service.payload[:rule], with: ::API::Entities::ExternalStatusCheck
          else
            render_api_error!(service.payload[:errors], service.http_status)
          end
        end
        desc 'List project\'s external approval rules' do
          detail 'This feature is gated by the :ff_external_status_checks feature flag.'
        end
        params do
          use :pagination
        end
        get do
          unauthorized! unless current_user.can?(:admin_project, user_project)

          present paginate(user_project.external_status_checks), with: ::API::Entities::ExternalStatusCheck
        end

        segment ':check_id' do
          desc 'Update an external approval rule' do
            success ::API::Entities::ExternalStatusCheck
            detail 'This feature is gated by the :ff_external_status_checks feature flag.'
          end
          params do
            requires :check_id, type: Integer, desc: 'The ID of the external status check'
            optional :name, type: String, desc: 'The name of the status check'
            optional :external_url, type: String, desc: 'The URL to notify when MR receives new commits'
            optional :protected_branch_ids,
                     type: Array[Integer],
                     coerce_with: ::API::Validations::Types::CommaSeparatedToIntegerArray.coerce,
                     desc: 'The protected branch ids for this check'
          end
          put do
            service = ::ExternalStatusChecks::UpdateService.new(
              container: user_project,
              current_user: current_user,
              params: declared_params(include_missing: false)
            ).execute

            if service.success?
              present service.payload[:rule], with: ::API::Entities::ExternalStatusCheck
            else
              render_api_error!(service.payload[:errors], service.http_status)
            end
          end

          desc 'Delete an external status check' do
            detail 'This feature is gated by the :ff_external_status_checks feature flag.'
          end
          params do
            requires :check_id, type: Integer, desc: 'The ID of the status check'
          end
          delete do
            external_status_check = user_project.external_status_checks.find(params[:check_id])

            destroy_conditionally!(external_status_check) do |external_status_check|
              ::ExternalStatusChecks::DestroyService.new(
                container: user_project,
                current_user: current_user
              ).execute(external_status_check)
            end
          end
        end
      end

      segment ':id/merge_requests/:merge_request_iid' do
        desc 'Externally approve a merge request' do
          detail 'This feature was introduced in 13.12 and is gated behind the :ff_external_status_checks feature flag.'
          success Entities::MergeRequests::StatusCheckResponse
        end
        params do
          requires :id, type: String, desc: 'The ID of a project'
          requires :merge_request_iid, type: Integer, desc: 'The IID of a merge request'
          requires :external_status_check_id, type: Integer, desc: 'The ID of a external status check'
          requires :sha, type: String, desc: 'The current SHA at HEAD of the merge request.'
        end
        post 'status_check_responses' do
          not_found! unless ::Feature.enabled?(:ff_external_status_checks, user_project)

          merge_request = find_merge_request_with_access(params[:merge_request_iid], :approve_merge_request)

          check_sha_param!(params, merge_request)

          approval = merge_request.status_check_responses.create!(external_status_check_id: params[:external_status_check_id], sha: params[:sha])

          present(approval, with: Entities::MergeRequests::StatusCheckResponse)
        end

        desc 'List all status checks for a merge request and their state.' do
          detail 'This feature was introduced in 13.12 and is gated behind the :ff_external_status_checks feature flag.'
        end
        get 'status_checks' do
          not_found! unless ::Feature.enabled?(:ff_external_status_checks, user_project)

          merge_request = find_merge_request_with_access(params[:merge_request_iid], :approve_merge_request)

          present(paginate(user_project.external_status_checks.applicable_to_branch(merge_request.target_branch)), with: Entities::MergeRequests::StatusCheck, merge_request: merge_request, sha: merge_request.source_branch_sha)
        end
      end
    end
  end
end
