# frozen_string_literal: true

module EE
  module UsersController
    def available_project_templates
      load_custom_project_templates
    end

    def available_group_templates
      load_group_project_templates
    end

    private

    def load_custom_project_templates
      @custom_project_templates ||= user.available_custom_project_templates(search: params[:search]).page(params[:page])
    end

    def load_group_project_templates
      @groups_with_project_templates ||=
        user.available_subgroups_with_custom_project_templates(params[:group_id])
            .page(params[:page])
    end
  end
end
