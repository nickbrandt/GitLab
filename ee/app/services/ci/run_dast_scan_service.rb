# frozen_string_literal: true

module Ci
  class RunDastScanService
    DEFAULT_SHA_FOR_PROJECTS_WITHOUT_COMMITS = :placeholder

    class RunError < StandardError
      attr_reader :full_messages

      def initialize(msg, full_messages = [])
        @full_messages = full_messages.unshift(msg)
        super(msg)
      end
    end

    def initialize(project:, user:)
      @project = project
      @user = user
    end

    def execute(branch:, target_url:)
      unless allowed?
        msg = Gitlab::Graphql::Authorize::AuthorizeResource::RESOURCE_ACCESS_ERROR
        raise RunError.new(msg)
      end

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
      reraise!(msg: 'Pipeline could not be created') do
        Ci::Pipeline.create!(
          project: project,
          ref: branch,
          sha: project.repository.commit&.id || DEFAULT_SHA_FOR_PROJECTS_WITHOUT_COMMITS,
          source: :ondemand_scan,
          user: user
        )
      end
    end

    def create_stage!(pipeline)
      reraise!(msg: 'Stage could not be created') do
        Ci::Stage.create!(
          name: 'dast',
          pipeline: pipeline,
          project: project
        )
      end
    end

    def create_build!(pipeline, stage, branch, target_url)
      reraise!(msg: 'Build could not be created') do
        Ci::Build.create!(
          name: 'DAST Scan',
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
      reraise!(msg: 'Build could not be enqueued') do
        build.enqueue!
      end
    end

    def reraise!(msg:)
      yield
    rescue ActiveRecord::RecordInvalid => err
      Gitlab::ErrorTracking.track_exception(err)
      raise RunError.new(msg, err.record.errors.full_messages)
    rescue => err
      Gitlab::ErrorTracking.track_exception(err)
      raise RunError.new(msg)
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
