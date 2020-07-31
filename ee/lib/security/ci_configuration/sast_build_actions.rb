# frozen_string_literal: true

module Security
  module CiConfiguration
    class SastBuildActions
      def initialize(auto_devops_enabled, params)
        @auto_devops_enabled = auto_devops_enabled
        @params = params
      end

      def generate
        config = {
          'stages' => stages,
          'variables' => parse_variables(global_variables),
          'sast' => sast_block,
          'include' => [{ 'template' => template }]
        }.select { |k, v| v.present? }

        content = config.to_yaml
        content << "# You can override the above template(s) by including variable overrides\n"
        content << "# See https://docs.gitlab.com/ee/user/application_security/sast/#customizing-the-sast-settings\n"

        [{ action: 'create', file_path: '.gitlab-ci.yml', content: content }]
      end

      private

      def stages
        base_stages = @auto_devops_enabled ? auto_devops_stages : ['test']
        (base_stages + [sast_stage]).uniq
      end

      def auto_devops_stages
        auto_devops_template = YAML.safe_load( Gitlab::Template::GitlabCiYmlTemplate.find('Auto-DevOps').content )
        auto_devops_template['stages']
      end

      def sast_stage
        @params[:stage] || 'test'
      end

      # We only want to write variables that are set
      def parse_variables(variables)
        variables.map { |var| [var, @params[var]] }.to_h.compact
      end

      def sast_block
        {
          'variables' => parse_variables(sast_variables),
          'stage' => sast_stage,
          'script' => ['/analyzer run']
        }.select { |k, v| v.present? }
      end

      def template
        return 'Auto-DevOps.gitlab-ci.yml' if @auto_devops_enabled

        'SAST.gitlab-ci.yml'
      end

      def global_variables
        %w(
          SECURE_ANALYZERS_PREFIX
        )
      end

      def sast_variables
        %w(
          SAST_ANALYZER_IMAGE_TAG
          SAST_EXCLUDED_PATHS
          SEARCH_MAX_DEPTH
        )
      end
    end
  end
end
