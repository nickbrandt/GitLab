# frozen_string_literal: true

module Spam
  class MarkAsSpamService
    include ::AkismetMethods

    attr_accessor :spammable, :options

    def initialize(spammable:)
      @spammable = spammable
      @options = {}

      @options[:ip_address] = @spammable.ip_address
      @options[:user_agent] = @spammable.user_agent
    end

    def mark_as_spam!
      return false unless spammable.submittable_as_spam?

      if akismet.submit_spam
        spammable.user_agent_detail.update_attribute(:submitted, true)
      else
        false
      end
    end
  end
end
