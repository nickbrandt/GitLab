# frozen_string_literal: true

module MergeRequests
  class WaitingForService
    attr_reader :merge_request

    WaitingFor = Struct.new(:requestee, :requester)

    def initialize(merge_request)
      @merge_request = merge_request
      @requestees = []
    end

    def wait_for(requestee, requester)
      waiting_for = WaitingFor.new(requestee, requester)

      return if find_waiting_for(requestee, requester).present?

      @requestees << waiting_for
    end

    def mark_as_done(requestee, requester)
      waiting_for = WaitingFor.new(requestee, requester)
      @requestees - [waiting_for]
    end

    def pending_users
      @requestees.map(&:requestee)
    end

    private

    def find_waiting_for(requestee, requester)
      return unless @requestees.present?

      @requestees.select { |w| w.requestee == requestee && w.requester == requester }
    end
  end
end
