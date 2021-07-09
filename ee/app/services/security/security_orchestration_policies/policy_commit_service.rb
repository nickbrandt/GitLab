# frozen_string_literal: true

module Security
  module SecurityOrchestrationPolicies
    class PolicyCommitService < ::BaseProjectService
      def execute
        @policy_configuration = project.security_orchestration_policy_configuration

        return error('Security Policy Project does not exist') unless policy_configuration.present?

        result = commit_policy(process_policy_yaml)

        return error(result[:message], :bad_request) if result[:status] != :success

        success({ branch: branch_name })
      rescue StandardError => e
        error(e.message, :bad_request)
      end

      private

      def process_policy_yaml
        policy = Gitlab::Config::Loader::Yaml.new(params[:policy_yaml]).load!
        updated_policy = ProcessPolicyService.new(
          policy_configuration: policy_configuration,
          params: { operation: params[:operation], policy: policy, type: policy.delete(:type)&.to_sym }
        ).execute

        YAML.dump(updated_policy.deep_stringify_keys)
      end

      def commit_policy(policy_yaml)
        return create_commit(::Files::UpdateService, policy_yaml) if policy_configuration.policy_configuration_exists?

        create_commit(::Files::CreateService, policy_yaml)
      end

      def create_commit(service, policy_yaml)
        service.new(policy_configuration.security_policy_management_project, current_user, policy_commit_attrs(policy_yaml)).execute
      end

      def policy_commit_attrs(policy_yaml)
        {
          commit_message: commit_message,
          file_path: Security::OrchestrationPolicyConfiguration::POLICY_PATH,
          file_content: policy_yaml,
          branch_name: branch_name,
          start_branch: policy_configuration.default_branch_or_main
        }
      end

      def commit_message
        operation = case params[:operation]
                    when :append then 'Add a new policy to'
                    when :replace then 'Update policy in'
                    when :remove then 'Delete policy in'
                    end

        "#{operation} #{Security::OrchestrationPolicyConfiguration::POLICY_PATH}"
      end

      def branch_name
        @branch_name ||= "update-policy-#{Time.now.to_i}"
      end

      attr_reader :project, :policy_configuration
    end
  end
end
