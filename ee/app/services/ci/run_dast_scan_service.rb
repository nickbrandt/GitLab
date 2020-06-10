# frozen_string_literal: true

module Ci
  class RunDastScanService
    DEFAULT_SHA_FOR_PROJECTS_WITHOUT_COMMITS = :placeholder

    EXCEPTIONS = [
      NotAllowed = Class.new(StandardError),
      CreatePipelineError = Class.new(StandardError),
      CreateStageError = Class.new(StandardError),
      CreateBuildError = Class.new(StandardError),
      EnqueueError = Class.new(StandardError)
    ].freeze

    def initialize(project:, user:)
      @project = project
      @user = user
    end

    def execute(branch:, target_url:)
      raise NotAllowed unless allowed?

      ActiveRecord::Base.transaction do
        pipeline = create_pipeline!(branch)
        stage = create_stage!(pipeline)
        build = create_build!(pipeline, stage, branch, target_url)
        enqueue!(build)
        pipeline
      end
    end

    private

    attr_reader :project, :user

    def allowed?
      Ability.allowed?(user, :create_pipeline, project)
    end

    def create_pipeline!(branch)
      reraise!(with: CreatePipelineError.new('Could not create pipeline')) do
        Ci::Pipeline.create!(
          project: project,
          ref: branch,
          sha: project.repository.commit&.id || DEFAULT_SHA_FOR_PROJECTS_WITHOUT_COMMITS,
          source: :web,
          user: user
        )
      end
    end

    def create_stage!(pipeline)
      reraise!(with: CreateStageError.new('Could not create stage')) do
        Ci::Stage.create!(
          name: 'dast',
          pipeline: pipeline,
          project: project
        )
      end
    end

    def create_build!(pipeline, stage, branch, target_url)
      reraise!(with: CreateBuildError.new('Could not create build')) do
        Ci::Build.create!(
          name: 'On demand DAST scan',
          pipeline: pipeline,
          project: project,
          ref: branch,
          scheduling_type: :stage,
          stage: stage.name,
          options: options,
          yaml_variables: yaml_variables(target_url)
        )
      end
    end

    def enqueue!(build)
      reraise!(with: EnqueueError.new('Could not enqueue build')) do
        build.enqueue!
      end
    end

    def reraise!(with:)
      yield
    rescue => err
      Gitlab::ErrorTracking.track_exception(err)
      raise with
    end

    def options
      {
        image: {
          name: '$SECURE_ANALYZERS_PREFIX/dast:$DAST_VERSION'
        },
        artifacts: {
          reports: {
            dast: [
              'gl-dast-report.json'
            ]
          }
        },
        script: [
          'export DAST_WEBSITE=${DAST_WEBSITE:-$(cat environment_url.txt)}',
          '/analyze'
        ]
      }
    end

    def yaml_variables(target_url)
      [
        {
          key: 'DAST_VERSION',
          value: '1',
          public: true
        },
        {
          key: 'SECURE_ANALYZERS_PREFIX',
          value: 'registry.gitlab.com/gitlab-org/security-products/analyzers',
          public: true
        },
        {
          key: 'DAST_WEBSITE',
          value: target_url,
          public: true
        },
        {
          key: 'GIT_STRATEGY',
          value: 'none',
          public: true
        }
      ]
    end
  end
end
