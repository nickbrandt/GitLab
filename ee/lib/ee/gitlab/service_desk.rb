# frozen_string_literal: true

module EE
  module Gitlab
    module ServiceDesk
      # Check whether a project or GitLab instance can support the Service Desk
      # feature. Use `project.service_desk_enabled?` to check whether it is
      # enabled for a particular project.
      def self.enabled?(project: nil)
        supported? && available?(project: project)
      end

      def self.supported?
        ::Gitlab::IncomingEmail.enabled? && ::Gitlab::IncomingEmail.supports_wildcard?
      end

      def self.available?(project: nil)
        (project || ::License).feature_available?(:service_desk)
      end
    end
  end
end
