# frozen_string_literal: true

module Gitlab
  module Elastic
    module Client
      # Takes a hash as returned by `ApplicationSetting#elasticsearch_config`,
      # and configures itself based on those parameters
      def self.build(config)
        base_config = {
          urls: config[:url],
          randomize_hosts: true,
          retry_on_failure: true
        }

        if config[:aws]
          creds = resolve_aws_credentials(config)
          region = config[:aws_region]

          ::Elasticsearch::Client.new(base_config) do |fmid|
            fmid.request(:aws_signers_v4, credentials: creds, service_name: 'es', region: region)
          end
        else
          ::Elasticsearch::Client.new(base_config)
        end
      end

      def self.resolve_aws_credentials(config)
        # Resolve credentials in order
        # 1.  Static config
        # 2.  ec2 instance profile
        static_credentials = Aws::Credentials.new(config[:aws_access_key], config[:aws_secret_access_key])

        return static_credentials if static_credentials&.set?

        # When static credentials are not configured, Aws::CredentialProviderChain API
        # will be used to retrieve credentials. It will check AWS access credential environment
        # variables, AWS credential profile, ECS credential service and EC2 credential service.
        # Please see aws-sdk-core/lib/aws-sdk-core/credential_provider_chain.rb for details of
        # the possible providers and order of the providers.
        instance_credentials = Aws::CredentialProviderChain.new.resolve
        instance_credentials if instance_credentials&.set?
      end
    end
  end
end
