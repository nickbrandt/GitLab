# frozen_string_literal: true

module ClustersCSP
  extend ActiveSupport::Concern

  included do
    content_security_policy do |policy|
      next if policy.directives.blank?

      connect_src_policy = policy.directives['connect-src'].to_a | %w(
        https://ec2.af-south-1.amazonaws.com
        https://ec2.ap-northeast-1.amazonaws.com
        https://ec2.ap-northeast-2.amazonaws.com
        https://ec2.ap-south-1.amazonaws.com
        https://ec2.ap-southeast-1.amazonaws.com
        https://ec2.ap-southeast-2.amazonaws.com
        https://ec2.ca-central-1.amazonaws.com
        https://ec2.eu-central-1.amazonaws.com
        https://ec2.eu-north-1.amazonaws.com
        https://ec2.eu-west-1.amazonaws.com
        https://ec2.eu-west-2.amazonaws.com
        https://ec2.eu-west-3.amazonaws.com
        https://ec2.sa-east-1.amazonaws.com
        https://ec2.us-east-1.amazonaws.com
        https://ec2.us-east-2.amazonaws.com
        https://ec2.us-west-1.amazonaws.com
        https://ec2.us-west-2.amazonaws.com
        https://iam.amazonaws.com
      )

      frame_src_policy = policy.directives['frame-src'].to_a | %w(
        https://content-cloudbilling.googleapis.com
        https://content-cloudresourcemanager.googleapis.com
        https://content-compute.googleapis.com
        https://content.googleapis.com
      )

      script_src_policy = policy.directives['script-src'].to_a | %w(
        https://apis.google.com
      )

      policy.connect_src(*connect_src_policy)
      policy.frame_src(*frame_src_policy)
      policy.script_src(*script_src_policy)
    end
  end
end
