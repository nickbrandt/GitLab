# frozen_string_literal: true

module Projects::Security::SastConfigurationHelper
  def sast_configuration_data(project)
    {
      sast_documentation_path: help_page_path('user/application_security/sast/index', anchor: 'configuration'),
      project_path: project.full_path
    }
  end
end
