# frozen_string_literal: true

module EE
  module Emails
    module Projects
      def mirror_was_hard_failed_email(project_id, user_id)
        @project = ::Project.find(project_id)

        mail(to: recipient(user_id, @project.group),
             subject: subject('Repository mirroring paused'))
      end

      def project_mirror_user_changed_email(new_mirror_user_id, deleted_user_name, project_id)
        @project = ::Project.find(project_id)
        @deleted_user_name = deleted_user_name

        mail(to: recipient(new_mirror_user_id, @project.group),
             subject: subject('Mirror user changed'))
      end

      def prometheus_alert_fired_email(project_id, user_id, alert_payload)
        @project = ::Project.find(project_id)

        @alert = ::Gitlab::Alerting::Alert
          .new(project: @project, payload: alert_payload)
          .present
        return unless @alert.valid?

        subject_text = "Alert: #{@alert.full_title}"
        mail(to: recipient(user_id, @project.group), subject: subject(subject_text))
      end
    end
  end
end
