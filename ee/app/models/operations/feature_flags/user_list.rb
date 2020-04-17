# frozen_string_literal: true

module Operations
  module FeatureFlags
    class UserList < ApplicationRecord
      include AtomicInternalId

      USERXID_MAX_LENGTH = 256

      self.table_name = 'operations_user_lists'

      belongs_to :project

      has_internal_id :iid, scope: :project, init: ->(s) { s&.project&.operations_feature_flags_user_lists&.maximum(:iid) }, presence: true

      validates :project, presence: true
      validates :name,
        presence: true,
        uniqueness: { scope: :project_id },
        length: 1..255
      validate :user_xids_validation

      private

      def user_xids_validation
        unless user_xids.is_a?(String) && !user_xids.match(/[\n\r\t]|,,/) && valid_xids?(user_xids.split(","))
          errors.add(:user_xids,
                     "user_xids must be a string of unique comma separated values each #{USERXID_MAX_LENGTH} characters or less")
        end
      end

      def valid_xids?(user_xids)
        user_xids.uniq.length == user_xids.length &&
          user_xids.all? { |xid| valid_xid?(xid) }
      end

      def valid_xid?(user_xid)
        user_xid.present? &&
          user_xid.strip == user_xid &&
          user_xid.length <= USERXID_MAX_LENGTH
      end
    end
  end
end
