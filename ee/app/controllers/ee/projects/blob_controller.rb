# frozen_string_literal: true

module EE
  module Projects
    module BlobController
      extend ActiveSupport::Concern

      prepended do
        before_action :validate_codeowner_rules, only: [:create, :update]
      end

      private

      # rubocop:disable Gitlab/ModuleWithInstanceVariables
      def validate_codeowner_rules
        return unless ::Feature.enabled?(:use_legacy_codeowner_validations)
        return if @file_path.blank?

        codeowners_error = codeowners_check_error(project, branch_name, @file_path)

        if codeowners_error.present?
          flash.now[:alert] = codeowners_error.tr("\n", " ")
          view = params[:action] == 'update' ? :edit : :new

          render view
        end
      end
      # rubocop:enable Gitlab/ModuleWithInstanceVariables

      def codeowners_check_error(project, branch_name, paths)
        ::Gitlab::CodeOwners::Validator.new(project, branch_name, paths).execute
      end
    end
  end
end
