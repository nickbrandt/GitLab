# frozen_string_literal: true

module EE
  module ProjectCiCdSetting
    extend ActiveSupport::Concern

    def merge_pipelines_enabled?
      project.feature_available?(:merge_pipelines) && super
    end

    def merge_trains_enabled?
      merge_pipelines_enabled? && project.feature_available?(:merge_trains) &&
        ::Feature.enabled?(:merge_trains_enabled, project, default_enabled: true)
    end

    def merge_pipelines_were_disabled?
      saved_change_to_attribute?(:merge_pipelines_enabled, from: true, to: false)
    end
  end
end
