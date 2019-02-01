# frozen_string_literal: true

module API
  class ProjectApprovalRules < ::Grape::API
    before { authenticate! }

    ARRAY_COERCION_LAMBDA = ->(val) { val.empty? ? [] : Array.wrap(val) }

    params do
      requires :id, type: String, desc: 'The ID of a project'
    end
    resource :projects, requirements: ::API::API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      segment ':id/approval_settings' do
        desc 'Get all project approval rules' do
          detail 'Private API subject to change'
          success EE::API::Entities::ProjectApprovalRules
        end
        get do
          authorize! :create_merge_request_in, user_project

          present user_project, with: EE::API::Entities::ProjectApprovalRules, current_user: current_user
        end

        desc 'Update fallback approvals required' do
          detail 'Private API subject to change'
          success ::API::Entities::Project
        end
        params do
          requires :fallback_approvals_required, as: :approvals_before_merge, type: Integer, desc: 'The total number of required approvals in case of fallback'
        end
        put do
          authorize! :admin_project, user_project

          result = ::Projects::UpdateService.new(user_project, current_user, declared_params).execute

          if result[:status] == :success
            present(
              user_project,
              with: ::API::Entities::Project,
              user_can_admin_project: can?(current_user, :admin_project, user_project)
            )
          else
            render_validation_error!(user_project)
          end
        end

        segment 'rules' do
          desc 'Create new approval rule' do
            detail 'Private API subject to change'
            success EE::API::Entities::ApprovalRule
          end
          params do
            requires :name, type: String, desc: 'The name of the approval rule'
            requires :approvals_required, type: Integer, desc: 'The number of required approvals for this rule'
            optional :users, as: :user_ids, type: Array, coerce_with: ARRAY_COERCION_LAMBDA, desc: 'The user ids for this rule'
            optional :groups, as: :group_ids, type: Array, coerce_with: ARRAY_COERCION_LAMBDA, desc: 'The group ids for this rule'
          end
          post do
            authorize! :admin_project, user_project

            result = ::ApprovalRules::CreateService.new(user_project, current_user, declared_params(include_missing: false)).execute

            if result[:status] == :success
              present result[:rule], with: EE::API::Entities::ApprovalRule, current_user: current_user
            else
              render_api_error!(result[:message], 400)
            end
          end

          segment ':approval_rule_id' do
            desc 'Update approval rule' do
              detail 'Private API subject to change'
              success EE::API::Entities::ApprovalRule
            end
            params do
              requires :approval_rule_id, type: Integer, desc: 'The ID of an approval_rule'
              optional :name, type: String, desc: 'The name of the approval rule'
              optional :approvals_required, type: Integer, desc: 'The number of required approvals for this rule'
              optional :users, as: :user_ids, type: Array, coerce_with: ARRAY_COERCION_LAMBDA, desc: 'The user ids for this rule'
              optional :groups, as: :group_ids, type: Array, coerce_with: ARRAY_COERCION_LAMBDA, desc: 'The group ids for this rule'
            end
            put do
              authorize! :admin_project, user_project

              params = declared_params(include_missing: false)
              puts params.inspect
              approval_rule = user_project.approval_rules.find(params.delete(:approval_rule_id))
              result = ::ApprovalRules::UpdateService.new(approval_rule, current_user, params).execute

              if result[:status] == :success
                present result[:rule], with: EE::API::Entities::ApprovalRule, current_user: current_user
              else
                render_api_error!(result[:message], 400)
              end
            end

            desc 'Delete an approval rule' do
              detail 'Private API subject to change'
            end
            params do
              requires :approval_rule_id, type: Integer, desc: 'The ID of an approval_rule'
            end
            delete do
              authorize! :admin_project, user_project

              approval_rule = user_project.approval_rules.find(params[:approval_rule_id])
              destroy_conditionally!(approval_rule)

              no_content!
            end
          end
        end
      end
    end
  end
end
