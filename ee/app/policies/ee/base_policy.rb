# frozen_string_literal: true

module EE
  module BasePolicy
    extend ActiveSupport::Concern

    prepended do
      with_scope :user
      condition(:auditor, score: 0) { @user&.auditor? }

      with_scope :user
      condition(:support_bot, score: 0) { @user&.support_bot? }

      with_scope :user
      condition(:alert_bot, score: 0) { @user&.alert_bot? }

      with_scope :user
      condition(:visual_review_bot, score: 0) { @user&.visual_review_bot? }

      with_scope :global
      condition(:license_block) { License.block_changes? }

      rule { auditor }.enable :read_all_resources
    end
  end
end
