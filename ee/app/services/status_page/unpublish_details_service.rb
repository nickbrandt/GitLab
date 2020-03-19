# frozen_string_literal: true

module StatusPage
  # Unpublish incident details from CDN.
  #
  # Example: An issue becomes confidential so it must be removed from CDN.
  #
  # This is an internal service which is part of
  # +StatusPage::PublishService+ and is not meant to be called directly.
  #
  # Consider calling +StatusPage::PublishService+ instead.
  class UnpublishDetailsService < PublishBaseService
    private

    def process(issue)
      key = object_key(issue)

      delete(key)
    end

    def object_key(issue)
      StatusPage::Storage.details_path(issue.iid)
    end
  end
end
