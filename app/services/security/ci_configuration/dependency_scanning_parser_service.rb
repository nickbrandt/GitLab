# frozen_string_literal: true

module Security
  module CiConfiguration
    # This class parses the Dependency Scannning template file and .gitlab-ci.yml to populate default and current values into the JSON
    # read from app/validators/json_schemas/security_ci_configuration_schemas/dependency_scanning_ui_schema.json
    class DependencyScanningParserService < ::BaseService
      include Gitlab::Utils::StrongMemoize

      DS_UI_SCHEMA_PATH = 'app/validators/json_schemas/security_ci_configuration_schemas/dependency_scanning_ui_schema.json'

      def initialize(project)
        @project = project
      end

      def configuration
        result = Gitlab::Json.parse(File.read(Rails.root.join(DS_UI_SCHEMA_PATH))).with_indifferent_access
        populate_default_value_for(result, :global)
        populate_default_value_for(result, :pipeline)
        fill_current_value_with_default_for(result, :global)
        fill_current_value_with_default_for(result, :pipeline)
        populate_current_value_for(result, :global)
        populate_current_value_for(result, :pipeline)

        fill_current_value_with_default_for_analyzers(result)
        populate_current_value_for_analyzers(result)

        result
      end

      private

      def dependency_scanning_template_content
        Gitlab::Template::GitlabCiYmlTemplate.find('DS').content
      end

      def populate_default_value_for(config, level)
        set_each(config[level], key: :default_value, with: dependency_scanning_template_attributes)
      end

      def populate_current_value_for(config, level)
        set_each(config[level], key: :value, with: gitlab_ci_yml_attributes)
      end

      def fill_current_value_with_default_for(config, level)
        set_each(config[level], key: :value, with: dependency_scanning_template_attributes)
      end

      def set_each(config_attributes, key:, with:)
        config_attributes.each do |entity|
          entity[key] = with[entity[:field]] if with[entity[:field]]
        end
      end

      def fill_current_value_with_default_for_analyzers(result)
        result[:analyzers].each do |analyzer|
          analyzer[:variables].each do |entity|
            entity[:value] = entity[:default_value] if entity[:default_value]
          end
        end
      end

      def populate_current_value_for_analyzers(result)
        result[:analyzers].each do |analyzer|
          analyzer[:enabled] = analyzer_enabled?(analyzer[:name])
          populate_current_value_for(analyzer, :variables)
        end
      end

      def analyzer_enabled?(analyzer_name)
        # Unless explicitly listed in the excluded analyzers, consider it enabled
        dependency_scanning_excluded_analyzers.exclude?(analyzer_name)
      end

      def dependency_scanning_excluded_analyzers
        strong_memoize(:dependency_scanning_excluded_analyzers) do
          excluded_analyzers = gitlab_ci_yml_attributes["DS_EXCLUDED_ANALYZERS"] || dependency_scanning_template_attributes["_EXCLUDED_ANALYZERS"]
          excluded_analyzers.split(',').map(&:strip) rescue []
        end
      end

      def dependency_scanning_template_attributes
        @dependency_scanning_template_attributes ||= build_dependency_scanning_attributes(dependency_scanning_template_content)
      end

      def gitlab_ci_yml_attributes
        @gitlab_ci_yml_attributes ||= begin
          config_content = @project.repository.blob_data_at(@project.repository.root_ref_sha, ci_config_file)
          return {} unless config_content

          build_dependency_scanning_attributes(config_content)
        end
      end

      def ci_config_file
        '.gitlab-ci.yml'
      end

      def build_dependency_scanning_attributes(content)
        options = { project: @project, user: current_user, sha: @project.repository.commit.sha }
        yaml_result = Gitlab::Ci::YamlProcessor.new(content, options).execute
        return {} unless yaml_result.valid?

        extract_required_attributes(yaml_result)
      end

      def extract_required_attributes(yaml_result)
        result = {}

        yaml_result.yaml_variables_for(:ds).each do |variable|
          result[variable[:key]] = variable[:value]
        end

        result[:stage] = yaml_result.stage_for(:ds)
        result.with_indifferent_access
      end
    end
  end
end
