# frozen_string_literal: true

module EE
  module Projects
    module MergeRequestsController
      extend ActiveSupport::Concern

      APPROVAL_RENDERING_ACTIONS = [:approve, :approvals, :unapprove].freeze

      prepended do
        include DescriptionDiffActions

        before_action only: [:show] do
          push_frontend_feature_flag(:sast_merge_request_report_api, default_enabled: true)
          push_frontend_feature_flag(:dast_merge_request_report_api, default_enabled: true)
          push_frontend_feature_flag(:container_scanning_merge_request_report_api, default_enabled: true)
          push_frontend_feature_flag(:dependency_scanning_merge_request_report_api, default_enabled: true)
          push_frontend_feature_flag(:parsed_license_report, default_enabled: true)
          push_frontend_feature_flag(:anonymous_visual_review_feedback)
        end

        before_action :whitelist_query_limiting_ee_merge, only: [:merge]
        before_action :whitelist_query_limiting_ee_show, only: [:show]
        before_action :authorize_read_pipeline!, only: [:container_scanning_reports, :dependency_scanning_reports, :sast_reports, :dast_reports]
      end

      def approve
        unless merge_request.can_approve?(current_user)
          return render_404
        end

        ::MergeRequests::ApprovalService
          .new(project, current_user)
          .execute(merge_request)

        render_approvals_json
      end

      def approvals
        render_approvals_json
      end

      def unapprove
        if merge_request.has_approved?(current_user)
          ::MergeRequests::RemoveApprovalService
            .new(project, current_user)
            .execute(merge_request)
        end

        render_approvals_json
      end

      def license_management_reports
        reports_response(merge_request.compare_license_management_reports(current_user))
      end

      def container_scanning_reports
        reports_response(merge_request.compare_container_scanning_reports(current_user))
      end

      def dependency_scanning_reports
        reports_response(merge_request.compare_dependency_scanning_reports(current_user))
      end

      def sast_reports
        reports_response(merge_request.compare_sast_reports(current_user))
      end

      def dast_reports
        reports_response(merge_request.compare_dast_reports(current_user))
      end

      def metrics_reports
        reports_response(merge_request.compare_metrics_reports)
      end

      protected

      # rubocop:disable Gitlab/ModuleWithInstanceVariables
      # Assigning both @merge_request and @issuable like in
      # `Projects::MergeRequests::ApplicationController`, and calling super if
      # we don't need the extra includes requires us to disable this cop.
      # rubocop: disable CodeReuse/ActiveRecord
      def merge_request
        return super unless APPROVAL_RENDERING_ACTIONS.include?(action_name.to_sym)

        @issuable = @merge_request ||= project.merge_requests
                                         .includes(
                                           :approved_by_users,
                                           approvers: :user
                                         )
                                         .find_by!(iid: params[:id])
        super
      end
      # rubocop: enable CodeReuse/ActiveRecord

      def render_approvals_json
        respond_to do |format|
          format.json do
            render json: EE::API::Entities::ApprovalState.new(
              merge_request.approval_state,
              current_user: current_user
            )
          end
        end
      end

      private

      def merge_access_check
        super_result = super

        return super_result if super_result
        return render_404 unless @merge_request.approved?
      end

      def whitelist_query_limiting_ee_merge
        ::Gitlab::QueryLimiting.whitelist('https://gitlab.com/gitlab-org/gitlab/issues/4792')
      end

      def whitelist_query_limiting_ee_show
        ::Gitlab::QueryLimiting.whitelist('https://gitlab.com/gitlab-org/gitlab/issues/4793')
      end
    end
  end
end
