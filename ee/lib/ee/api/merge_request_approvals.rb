# frozen_string_literal: true

module EE
  module API
    module MergeRequestApprovals
      extend ActiveSupport::Concern

      prepended do
        before { authenticate_non_get! }

        helpers do
          params :ee_approval_params do
            optional :approval_password, type: String, desc: 'Current user\'s password if project is set to require explicit auth on approval'
          end

          def present_approval(merge_request)
            present merge_request.approval_state, with: ::EE::API::Entities::ApprovalState, current_user: current_user
          end

          def handle_merge_request_errors!(errors)
            if errors.has_key? :project_access
              error!(errors[:project_access], 422)
            elsif errors.has_key? :branch_conflict
              error!(errors[:branch_conflict], 422)
            elsif errors.has_key? :validate_fork
              error!(errors[:validate_fork], 422)
            elsif errors.has_key? :validate_branches
              conflict!(errors[:validate_branches])
            elsif errors.has_key? :base
              error!(errors[:base], 422)
            end

            render_api_error!(errors, 400)
          end

          def present_merge_request_approval_state(presenter:, target_branch: nil)
            merge_request = find_merge_request_with_access(params[:merge_request_iid])

            present(
              merge_request.approval_state(target_branch: target_branch),
              with: presenter,
              current_user: current_user
            )
          end
        end

        params do
          requires :id, type: String, desc: 'The ID of a project'
          requires :merge_request_iid, type: Integer, desc: 'The IID of a merge request'
        end
        resource :projects, requirements: ::API::API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
          segment ':id/merge_requests/:merge_request_iid' do
            desc 'List approval rules for merge request', {
              success: ::EE::API::Entities::MergeRequestApprovalSettings,
              hidden: true
            }
            params do
              optional :target_branch, type: String, desc: 'Branch that scoped approval rules apply to'
            end
            get 'approval_settings' do
              present_merge_request_approval_state(
                presenter: ::EE::API::Entities::MergeRequestApprovalSettings,
                target_branch: declared_params[:target_branch]
              )
            end

            desc 'Get approval state of merge request' do
              success ::EE::API::Entities::MergeRequestApprovalState
            end
            get 'approval_state' do
              present_merge_request_approval_state(presenter: ::EE::API::Entities::MergeRequestApprovalState)
            end

            desc 'Change approval-related configuration' do
              detail 'This feature was introduced in 10.6'
              success ::EE::API::Entities::ApprovalState
            end
            params do
              requires :approvals_required, type: Integer, desc: 'The amount of approvals required. Must be higher than the project approvals'
            end
            post 'approvals' do
              merge_request = find_merge_request_with_access(params[:merge_request_iid], :update_merge_request)

              error!('Overriding approvals is disabled', 422) if merge_request.project.disable_overriding_approvers_per_merge_request

              merge_request = ::MergeRequests::UpdateService.new(user_project, current_user, approvals_before_merge: params[:approvals_required]).execute(merge_request)

              if merge_request.valid?
                present_approval(merge_request)
              else
                handle_merge_request_errors! merge_request.errors
              end
            end

            desc 'Update approvers and approver groups' do
              detail 'This feature was introduced in 10.6'
              success ::EE::API::Entities::ApprovalState
            end
            params do
              requires :approver_ids, type: Array[Integer], coerce_with: ::API::Validations::Types::CommaSeparatedToIntegerArray.coerce,
                desc: 'Array of User IDs to set as approvers.'
              requires :approver_group_ids, type: Array[Integer], coerce_with: ::API::Validations::Types::CommaSeparatedToIntegerArray.coerce,
                desc: 'Array of Group IDs to set as approvers.'
            end
            put 'approvers' do
              ::Gitlab::QueryLimiting.whitelist('https://gitlab.com/gitlab-org/gitlab/issues/8883')

              merge_request = find_merge_request_with_access(params[:merge_request_iid], :update_approvers)

              merge_request = ::MergeRequests::UpdateService.new(user_project, current_user, declared(params, include_parent_namespaces: false).merge(remove_old_approvers: true)).execute(merge_request)

              if merge_request.valid?
                present_approval(merge_request)
              else
                handle_merge_request_errors! merge_request.errors
              end
            end
          end
        end
      end
    end
  end
end
