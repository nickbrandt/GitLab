# frozen_string_literal: true

module Vulnerabilities
  class ResolveService
    include Gitlab::Allowable

    def initialize(user, vulnerability)
      @user = user
      @vulnerability = vulnerability
    end

    def execute
      raise Gitlab::Access::AccessDeniedError unless can?(@user, :resolve_vulnerability, @vulnerability.project)

      @vulnerability.tap do |vulnerability|
        vulnerability.update(state: :closed, closed_by: @user, closed_at: Time.zone.now)
      end
    end
  end
end
