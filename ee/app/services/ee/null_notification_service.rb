# frozen_string_literal: true

# This class can be used as a drop-in for NotificationService in order to
# prevent sending notifications.
#
# It will respond to any message that NotificationService responds to with
# itself in order to support method chaining.
module EE
  class NullNotificationService
    def method_missing(name, *)
      if respond_to_missing?(name)
        self
      else
        super
      end
    end

    def respond_to_missing?(name, *)
      ::NotificationService.method_defined?(name)
    end
  end
end
