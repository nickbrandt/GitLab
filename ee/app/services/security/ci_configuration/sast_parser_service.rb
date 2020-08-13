# frozen_string_literal: true

module Security
  module CiConfiguration
    # This class parses SAST template file and .gitlab-ci.yml to populate default and current values into the JSON
    # read from app/validators/json_schemas/security_ci_configuration_schemas/sast_ui_schema.json
    class SastParserService < ::BaseService
      SAST_UI_SCHEMA_PATH = 'app/validators/json_schemas/security_ci_configuration_schemas/sast_ui_schema.json'

      def initialize(project)
        @project = project
      end

      def configuration
        config = Gitlab::Json.parse(File.read(Rails.root.join(SAST_UI_SCHEMA_PATH))).with_indifferent_access
        populate_values(config)
        config
      end

      private

      def sast_template_content
        Gitlab::Template::GitlabCiYmlTemplate.find('SAST').content
      end

      def populate_values(config)
        set_each(config[:global], key: :default_value, with: sast_template_attributes)
        set_each(config[:global], key: :value, with: gitlab_ci_yml_attributes)
        set_each(config[:pipeline], key: :default_value, with: sast_template_attributes)
        set_each(config[:pipeline], key: :value, with: gitlab_ci_yml_attributes)
      end

      def set_each(config_attributes, key:, with:)
        config_attributes.each do |entity|
          entity[key] = with[entity[:field]]
        end
      end

      def sast_template_attributes
        @sast_template_attributes ||= build_sast_attributes(sast_template_content)
      end

      def gitlab_ci_yml_attributes
        @gitlab_ci_yml_attributes ||= begin
          config_content = @project.repository.blob_data_at(@project.repository.root_ref_sha, ci_config_file)

          return {} unless config_content

          build_sast_attributes(config_content)
        end
      end

      def ci_config_file
        '.gitlab-ci.yml'
      end

      def build_sast_attributes(content)
        options = { project: @project, user: current_user, sha: @project.repository.commit.sha }
        sast_attributes = Gitlab::Ci::YamlProcessor.new(content, options).build_attributes(:sast)
        extract_required_attributes(sast_attributes)
      end

      def extract_required_attributes(attributes)
        result = {}
        attributes[:yaml_variables].each do |variable|
          result[variable[:key]] = variable[:value]
        end

        result[:stage] = attributes[:stage]
        result.with_indifferent_access
      end
    end
  end
end
