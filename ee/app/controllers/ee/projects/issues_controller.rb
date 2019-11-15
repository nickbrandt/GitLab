# frozen_string_literal: true

module EE
  module Projects
    module IssuesController
      extend ActiveSupport::Concern
      extend ::Gitlab::Utils::Override

      prepended do
        include DescriptionDiffActions

        # Specifying before_action :authenticate_user! multiple times
        # doesn't work, since the last filter will override the previous
        # ones.
        alias_method :export_csv_authenticate_user!, :authenticate_user!

        before_action :export_csv_authenticate_user!, only: [:export_csv]
        before_action :check_export_issues_available!, only: [:export_csv]
        before_action :check_service_desk_available!, only: [:service_desk]
        before_action :whitelist_query_limiting_ee, only: [:update]
      end

      override :issue_except_actions
      def issue_except_actions
        super + %i[export_csv service_desk]
      end

      override :set_issuables_index_only_actions
      def set_issuables_index_only_actions
        super + %i[service_desk]
      end

      def service_desk
        @issues = @issuables # rubocop:disable Gitlab/ModuleWithInstanceVariables
        @users.push(::User.support_bot) # rubocop:disable Gitlab/ModuleWithInstanceVariables
      end

      def export_csv
        ExportCsvWorker.perform_async(current_user.id, project.id, finder_options.to_h)

        index_path = project_issues_path(project)
        redirect_to(index_path, notice: "Your CSV export has started. It will be emailed to #{current_user.notification_email} when complete.")
      end

      private

      def issue_params_attributes
        attrs = super
        attrs.unshift(:weight) if project.feature_available?(:issue_weights)

        attrs
      end

      def finder_options
        options = super
        options.reject! { |key| key == 'weight' } unless project.feature_available?(:issue_weights)

        if service_desk?
          options.reject! { |key| key == 'author_username' || key == 'author_id' }
          options[:author_id] = ::User.support_bot
        end

        options
      end

      def service_desk?
        action_name == 'service_desk'
      end

      def whitelist_query_limiting_ee
        ::Gitlab::QueryLimiting.whitelist('https://gitlab.com/gitlab-org/gitlab/issues/4794')
      end
    end
  end
end
