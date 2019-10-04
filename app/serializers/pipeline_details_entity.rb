# frozen_string_literal: true

class PipelineDetailsEntity < PipelineEntity
  expose :flags do
    expose :latest?, as: :latest
  end

  expose :details do
    expose :artifacts, using: BuildArtifactEntity
    expose :test_reports, using: TestReportEntity do |pipeline|
      pipeline.test_reports.total_count.zero? ? nil : pipeline.test_reports
    rescue
      nil
    end
    expose :manual_actions, using: BuildActionEntity
    expose :scheduled_actions, using: BuildActionEntity
  end
end

PipelineDetailsEntity.prepend_if_ee('EE::PipelineDetailsEntity')
