# frozen_string_literal: true

module Security
  class ReportFetchService
    def initialize(project, artifact)
      @project = project
      @artifact = artifact
    end

    def self.pipeline_for(project)
      project.all_pipelines.latest_successful_for_ref(project.default_branch)
    end

    def pipeline
      @pipeline ||= self.class.pipeline_for(project)
    end

    def build
      return unless pipeline

      @build ||= pipeline.builds.latest
                   .with_reports(artifact)
                   .last
    end

    def able_to_fetch?
      build&.success?
    end

    private

    attr_reader :project, :artifact
  end
end
