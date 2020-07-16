# frozen_string_literal: true

module Ci
  class RunDastScanService < BaseService
    def self.ci_template_raw
      @ci_template_raw ||= Gitlab::Template::GitlabCiYmlTemplate.find('DAST').content
    end

    def self.ci_template
      @ci_template ||= YAML.safe_load(ci_template_raw).tap do |template|
        template['stages'] = ['dast']
        template['dast'].delete('rules')
      end
    end

    def execute(branch:, target_url:)
      return ServiceResponse.error(message: 'Insufficient permissions') unless allowed?

      service = Ci::CreatePipelineService.new(project, current_user, ref: branch)
      pipeline = service.execute(:ondemand_dast_scan, content: ci_yaml(target_url))

      if pipeline.created_successfully?
        ServiceResponse.success(payload: pipeline)
      else
        ServiceResponse.error(message: pipeline.full_error_messages)
      end
    end

    private

    def allowed?
      Ability.allowed?(current_user, :run_ondemand_dast_scan, project)
    end

    def ci_yaml(target_url)
      self.class.ci_template.deep_merge(
        'variables' => { 'DAST_WEBSITE' => target_url }
      ).to_yaml
    end
  end
end
