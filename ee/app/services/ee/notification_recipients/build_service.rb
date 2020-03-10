# frozen_string_literal: true

module EE
  module NotificationRecipients
    module BuildService
      extend ActiveSupport::Concern

      class_methods do
        def build_new_review_recipients(*args)
          NotificationRecipients::Builder::NewReview.new(*args).notification_recipients
        end
      end
    end
  end
end
