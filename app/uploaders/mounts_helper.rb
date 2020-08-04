# frozen_string_literal: true

module MountsHelper
  def changed_mounts
    # rubocop:disable GitlabSecurity/PublicSend
    self.class.uploaders.select do |mount, uploader_class|
      mounted_as = uploader_class.serialization_column(self.class, mount)
      uploader = send(:"#{mounted_as}")

      uploader && uploader.exists? && send(:"saved_change_to_#{mounted_as}?")
    end.keys
    # rubocop:enable GitlabSecurity/PublicSend
  end
end
