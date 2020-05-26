# frozen_string_literal: true

module EE
  module Projects
    module BlobController
      extend ActiveSupport::Concern

      prepended do
        before_action :validate_codeowner_rules, only: [:create, :update]
      end

      private

      def validate_codeowner_rules
        return if params[:file_path].blank?

        codeowners_error = codeowners_check_error(project, branch_name, params[:file_path])

        if codeowners_error.present?
          flash.now[:alert] = codeowners_error
          view = params[:action] == 'update' ? :edit : :new

          render view
        end
      end

      def codeowners_check_error(project, branch_name, paths)
        ::Gitlab::CodeOwners::Validator.new(project, branch_name, paths).execute
      end
    end
  end
end
