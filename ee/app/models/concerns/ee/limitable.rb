# frozen_string_literal: true

module EE
  module Limitable
    extend ActiveSupport::Concern

    included do
      validate :validate_plan_limit_not_exceeded, on: :create
    end

    private

    def validate_plan_limit_not_exceeded
      return unless project

      limit_name = self.class.name.demodulize.tableize
      relation = self.class.where(project: project)

      if project.actual_limits.exceeded?(limit_name, relation)
        errors.add(:base, _("Maximum number of %{name} (%{count}) exceeded") %
          { name: limit_name.humanize(capitalize: false), count: project.actual_limits.public_send(limit_name) }) # rubocop:disable GitlabSecurity/PublicSend
      end
    end
  end
end
