# frozen_string_literal: true

module Operations
  module FeatureFlags
    class Strategy < ApplicationRecord
      STRATEGY_DEFAULT = 'default'
      STRATEGY_GRADUALROLLOUTUSERID = 'gradualRolloutUserId'
      STRATEGY_USERWITHID = 'userWithId'
      STRATEGIES = {
        STRATEGY_DEFAULT => [].freeze,
        STRATEGY_GRADUALROLLOUTUSERID => %w[groupId percentage].freeze,
        STRATEGY_USERWITHID => ['userIds'].freeze
      }.freeze
      USERID_MAX_LENGTH = 256

      self.table_name = 'operations_strategies'

      belongs_to :feature_flag

      validates :name,
        inclusion: {
        in: STRATEGIES.keys,
        message: 'strategy name is invalid'
      }

      validate :parameters_validations, if: -> { errors[:name].blank? }

      private

      def parameters_validations
        validate_parameters_type &&
          validate_parameters_keys &&
          validate_parameters_values
      end

      def validate_parameters_type
        parameters.is_a?(Hash) || parameters_error('parameters are invalid')
      end

      def validate_parameters_keys
        actual_keys = parameters.keys.sort
        expected_keys = STRATEGIES[name].sort
        expected_keys == actual_keys || parameters_error('parameters are invalid')
      end

      def validate_parameters_values
        case name
        when STRATEGY_GRADUALROLLOUTUSERID
          gradual_rollout_user_id_parameters_validation
        when STRATEGY_USERWITHID
          user_with_id_parameters_validation
        end
      end

      def gradual_rollout_user_id_parameters_validation
        percentage = parameters['percentage']
        group_id = parameters['groupId']

        unless percentage.is_a?(String) && percentage.match(/\A[1-9]?[0-9]\z|\A100\z/)
          parameters_error('percentage must be a string between 0 and 100 inclusive')
        end

        unless group_id.is_a?(String) && group_id.match(/\A[a-z]{1,32}\z/)
          parameters_error('groupId parameter is invalid')
        end
      end

      def user_with_id_parameters_validation
        user_ids = parameters['userIds']
        unless user_ids.is_a?(String) && !user_ids.match(/[\n\r\t]|,,/) && valid_ids?(user_ids.split(","))
          parameters_error("userIds must be a string of unique comma separated values each #{USERID_MAX_LENGTH} characters or less")
        end
      end

      def valid_ids?(user_ids)
        user_ids.uniq.length == user_ids.length &&
          user_ids.all? { |id| valid_id?(id) }
      end

      def valid_id?(user_id)
        user_id.present? &&
          user_id.strip == user_id &&
          user_id.length <= USERID_MAX_LENGTH
      end

      def parameters_error(message)
        errors.add(:parameters, message)
        false
      end
    end
  end
end
