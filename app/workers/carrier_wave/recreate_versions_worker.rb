# frozen_string_literal: true

module CarrierWave
  class RecreateVersionsWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker
    feature_category_not_owned!
    idempotent!
    sidekiq_options retry: 5
    loggable_arguments 0, 1, 2, 3
    deduplicate :until_executed

    def perform(subject_class_name, mounted_as, subject_id)
      subject_class = subject_class_name.constantize

      subject = subject_class.find(subject_id)

      uploader = build_uploader(subject, mounted_as&.to_sym)

      uploader.recreate_versions_async!
    end

    def build_uploader(subject, mount_point)
      subject.send(mount_point) # rubocop:disable GitlabSecurity/PublicSend
    end
  end
end
