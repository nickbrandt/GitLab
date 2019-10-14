# frozen_string_literal: true

module EE
  module ProjectCiCdSetting
    extend ActiveSupport::Concern

    def merge_pipelines_enabled?
      project.feature_available?(:merge_pipelines) && super
    end

    # As of GitLab 12.1, merge trains option is enabled by default for all projects.
    # We should drop `merge_trains_enabled` column after this application has been deployed.
    # See more https://gitlab.com/gitlab-org/gitlab/issues/11222.
    def merge_trains_enabled?
      merge_pipelines_enabled? && project.feature_available?(:merge_trains) &&
        ::Feature.enabled?(:merge_trains_enabled, project, default_enabled: true)
    end

    def merge_pipelines_were_disabled?
      saved_change_to_attribute?(:merge_pipelines_enabled, from: true, to: false)
    end
  end
end
