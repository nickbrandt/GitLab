# frozen_string_literal: true
# EE fixture
Gitlab::Seeder.quiet do
  Project.all.sample(5).each do |project|
    project.ci_pipelines.all.sample(2).each do |pipeline|
      next if pipeline.source_pipeline

      target_pipeline = Ci::Pipeline
        .where.not(project: project)
        .order('random()').first

      # link to source pipeline
      pipeline.sourced_pipelines.create!(
        source_job: pipeline.builds.all.sample,
        source_project: pipeline.project,
        project: target_pipeline.project,
        pipeline: target_pipeline
      )
    end
  end
end
