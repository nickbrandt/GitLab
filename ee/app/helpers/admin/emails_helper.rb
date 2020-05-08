# frozen_string_literal: true

module Admin
  module EmailsHelper
    def send_emails_from_admin_area_feature_available?
      License.feature_available?(:send_emails_from_admin_area)
    end
  end
end
