# frozen_string_literal: true

module EE
  module BasePolicy
    extend ActiveSupport::Concern

    prepended do
      with_scope :user
      condition(:auditor, score: 0) { @user&.auditor? }

      with_scope :global
      condition(:license_block) { License.block_changes? }

      rule { auditor }.enable :read_all_resources
    end
  end
end
