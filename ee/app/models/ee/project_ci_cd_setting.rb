# frozen_string_literal: true

module EE
  module ProjectCiCdSetting
    extend ActiveSupport::Concern

    def merge_pipelines_enabled?
      project.feature_available?(:merge_pipelines) && super
    end

    def merge_trains_enabled?
      merge_pipelines_enabled? && project.feature_available?(:merge_trains) && super
    end
  end
end
