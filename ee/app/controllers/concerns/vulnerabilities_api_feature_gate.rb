# frozen_string_literal: true

# TODO: remove this module and its usages when :first_class_vulnerabilities feature flag is removed
# https://gitlab.com/gitlab-org/gitlab/issues/33488
module VulnerabilitiesApiFeatureGate
  extend ActiveSupport::Concern

  included do
    before_action :verify_vulnerabilities_action_enabled!

    def verify_vulnerabilities_action_enabled!
      access_denied! unless vulnerabilities_action_enabled?
    end

    def vulnerabilities_action_enabled?
      raise NotImplementedError('Must be implemented in the including controller class')
    end
  end
end
