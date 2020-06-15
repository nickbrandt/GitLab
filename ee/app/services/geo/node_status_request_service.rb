# frozen_string_literal: true

module Geo
  class NodeStatusRequestService < RequestService
    include Gitlab::Geo::LogHelpers

    def execute(status)
      return false unless primary_node.present?

      super(primary_status_url, payload(status))
    end

    private

    def primary_status_url
      primary_node&.status_url
    end

    def payload(status)
      status.attributes.except('id')
    end
  end
end
