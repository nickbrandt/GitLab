# frozen_string_literal: true

module EE
  module NotificationRecipientService
    extend ActiveSupport::Concern

    class_methods do
      def build_new_review_recipients(*args)
        NotificationRecipientService::Builder::NewReview.new(*args).notification_recipients
      end
    end

    prepended do
      module Builder
        class NewReview < ::NotificationRecipientService::Builder::Base
          attr_reader :review
          def initialize(review)
            @review = review
          end

          def target
            review.merge_request
          end

          def project
            review.project
          end

          def group
            project.group
          end

          def build!
            add_participants(review.author)
            add_mentions(review.author, target: review)
            add_project_watchers
            add_custom_notifications
            add_subscribed_users
          end

          # A new review is a batch of new notes
          # therefore new_note subscribers should also
          # receive incoming new reviews
          def custom_action
            :new_note
          end

          def acting_user
            review.author
          end
        end
      end
    end
  end
end
