# frozen_string_literal: true

module Security
  module CiConfiguration
    class SastBuildActions
      def initialize(auto_devops_enabled, params, existing_gitlab_ci_content, default_sast_values)
        @auto_devops_enabled = auto_devops_enabled
        @params = params
        @existing_gitlab_ci_content = existing_gitlab_ci_content || {}
        @default_sast_values = default_sast_values
      end

      def generate
        action = @existing_gitlab_ci_content.present? ? 'update' : 'create'

        update_existing_content!

        [{ action: action, file_path: '.gitlab-ci.yml', content: prepare_existing_content }]
      end

      private

      def update_existing_content!
        @existing_gitlab_ci_content['stages'] = set_stages
        @existing_gitlab_ci_content['variables'] = set_variables(global_variables, @existing_gitlab_ci_content)
        @existing_gitlab_ci_content['sast'] = set_sast_block
        @existing_gitlab_ci_content['include'] = set_includes

        @existing_gitlab_ci_content.select! { |k, v| v.present? }
        @existing_gitlab_ci_content['sast'].select! { |k, v| v.present? }
      end

      def set_includes
        includes = @existing_gitlab_ci_content['include'] || []
        includes = includes.is_a?(Array) ? includes : [includes]
        includes << { 'template' => template }
        includes.uniq
      end

      def set_stages
        existing_stages = @existing_gitlab_ci_content['stages'] || []
        base_stages = @auto_devops_enabled ? auto_devops_stages : ['test']
        (existing_stages + base_stages + [sast_stage]).uniq
      end

      def auto_devops_stages
        auto_devops_template = YAML.safe_load( Gitlab::Template::GitlabCiYmlTemplate.find('Auto-DevOps').content )
        auto_devops_template['stages']
      end

      def sast_stage
        @params['stage'].presence ? @params['stage'] : 'test'
      end

      def set_variables(variables, hash_to_update = {})
        hash_to_update['variables'] ||= {}

        variables.each do |key|
          if @params[key].present? && @params[key].to_s != @default_sast_values[key].to_s
            hash_to_update['variables'][key] = @params[key]
          else
            hash_to_update['variables'].delete(key)
          end
        end

        hash_to_update['variables']
      end

      def set_sast_block
        sast_content = @existing_gitlab_ci_content['sast'] || {}
        sast_content['variables'] = set_variables(sast_variables)
        sast_content['stage'] = sast_stage
        sast_content.select { |k, v| v.present? }
      end

      def prepare_existing_content
        content = @existing_gitlab_ci_content.to_yaml
        content = remove_document_delimeter(content)

        content.prepend(sast_comment)
      end

      def remove_document_delimeter(content)
        content.gsub(/^---\n/, '')
      end

      def sast_comment
        <<~YAML
          # You can override the included template(s) by including variable overrides
          # See https://docs.gitlab.com/ee/user/application_security/sast/#customizing-the-sast-settings
          # Note that environment variables can be set in several places
          # See https://docs.gitlab.com/ee/ci/variables/#priority-of-environment-variables
        YAML
      end

      def template
        return 'Auto-DevOps.gitlab-ci.yml' if @auto_devops_enabled

        'Security/SAST.gitlab-ci.yml'
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
