# frozen_string_literal: true

module EE
  module ProjectUnauthorized
    extend ::Gitlab::Utils::Override

    override :project_unauthorized_proc
    def project_unauthorized_proc
      lambda do |project|
        if project
          label = project.external_authorization_classification_label
          rejection_reason = nil

          unless EE::Gitlab::ExternalAuthorization.access_allowed?(current_user, label)
            rejection_reason = EE::Gitlab::ExternalAuthorization.rejection_reason(current_user, label)
            rejection_reason ||= _('External authorization denied access to this project')
          end

          if rejection_reason
            access_denied!(rejection_reason)
          end
        end
      end
    end
  end
end
