# frozen_string_literal: true

module Gitlab
  module Ci
    #
    # Base GitLab CI Configuration facade
    #
    class Config
      ConfigError = Class.new(StandardError)
      TIMEOUT_SECONDS = 30.seconds
      TIMEOUT_MESSAGE = 'Resolving config took longer than expected'

      RESCUE_ERRORS = [
        Gitlab::Config::Loader::FormatError,
        Extendable::ExtensionError,
        External::Processor::IncludeError,
        Config::Yaml::Tags::TagError
      ].freeze

      attr_reader :root, :context, :ref

      def initialize(config, project: nil, sha: nil, user: nil, parent_pipeline: nil, ref: nil)
        @context = build_context(project: project, sha: sha, user: user, parent_pipeline: parent_pipeline)
        @context.set_deadline(TIMEOUT_SECONDS)

        @ref = ref

        @config = expand_config(config)

        @root = Entry::Root.new(@config)
        @root.compose!

      rescue *rescue_errors => e
        raise Config::ConfigError, e.message
      end

      def valid?
        @root.valid?
      end

      def errors
        @root.errors
      end

      def warnings
        @root.warnings
      end

      def to_hash
        @config
      end

      ##
      # Temporary method that should be removed after refactoring
      #
      def variables
        root.variables_value
      end

      def variables_with_data
        root.variables_entry.value_with_data
      end

      def stages
        root.stages_value
      end

      def jobs
        root.jobs_value
      end

      def normalized_jobs
        @normalized_jobs ||= Ci::Config::Normalizer.new(jobs).normalize_jobs
      end

      def included_templates
        @context.expandset.filter_map { |i| i[:template] }
      end

      private

      def expand_config(config)
        build_config(config)

      rescue Gitlab::Config::Loader::Yaml::DataTooLargeError => e
        track_and_raise_for_dev_exception(e)
        raise Config::ConfigError, e.message

      rescue Gitlab::Ci::Config::External::Context::TimeoutError => e
        track_and_raise_for_dev_exception(e)
        raise Config::ConfigError, TIMEOUT_MESSAGE
      end

      def build_config(config)
        if ::Feature.enabled?(:ci_custom_yaml_tags, @context.project, default_enabled: :yaml)
          build_config_with_custom_tags(config)
        else
          build_config_without_custom_tags(config)
        end
      end

      def build_config_with_custom_tags(config)
        initial_config = Config::Yaml.load!(config, project: @context.project)
        initial_config = Config::External::Processor.new(initial_config, @context).perform
        initial_config = Config::Extendable.new(initial_config).to_hash
        initial_config = Config::Yaml::Tags::Resolver.new(initial_config).to_hash
        initial_config = Config::EdgeStagesInjector.new(initial_config).to_hash

        initial_config
      end

      def build_config_without_custom_tags(config)
        initial_config = Gitlab::Config::Loader::Yaml.new(config).load!
        initial_config = Config::External::Processor.new(initial_config, @context).perform
        initial_config = Config::Extendable.new(initial_config).to_hash
        initial_config = Config::EdgeStagesInjector.new(initial_config).to_hash

        initial_config
      end

      def build_context(project:, sha:, user:, parent_pipeline:)
        Config::External::Context.new(
          project: project,
          sha: sha || project&.repository&.root_ref_sha,
          user: user,
          parent_pipeline: parent_pipeline,
          variables: project&.predefined_variables&.to_runner_variables)
      end

      def track_and_raise_for_dev_exception(error)
        Gitlab::ErrorTracking.track_and_raise_for_dev_exception(error, @context.sentry_payload)
      end

      # Overridden in EE
      def rescue_errors
        RESCUE_ERRORS
      end
    end
  end
end

Gitlab::Ci::Config.prepend_if_ee('EE::Gitlab::Ci::ConfigEE')
