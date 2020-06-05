# frozen_string_literal: true

module EE
  module Projects
    module IssuesController
      extend ActiveSupport::Concern
      extend ::Gitlab::Utils::Override

      prepended do
        include DescriptionDiffActions

        before_action :check_service_desk_available!, only: [:service_desk]
        before_action :whitelist_query_limiting_ee, only: [:update]

        before_action do
          push_frontend_feature_flag(:save_issuable_health_status, project.group, default_enabled: true)
        end
      end

      override :issue_except_actions
      def issue_except_actions
        super + %i[service_desk]
      end

      override :set_issuables_index_only_actions
      def set_issuables_index_only_actions
        super + %i[service_desk]
      end

      def service_desk
        @issues = @issuables # rubocop:disable Gitlab/ModuleWithInstanceVariables
        @users.push(::User.support_bot) # rubocop:disable Gitlab/ModuleWithInstanceVariables
      end

      private

      def issue_params_attributes
        attrs = super
        attrs.unshift(:weight) if project.feature_available?(:issue_weights)
        attrs.unshift(:epic_id) if project.group&.feature_available?(:epics)

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
