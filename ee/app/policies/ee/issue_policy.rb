# frozen_string_literal: true

module EE
  module IssuePolicy
    extend ActiveSupport::Concern
    prepended do
      rule { ~can?(:read_issue) }.policy do
        prevent :read_design
        prevent :create_design
        prevent :destroy_design
      end
    end
  end
end
