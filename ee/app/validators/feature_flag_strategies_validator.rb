# frozen_string_literal: true

class FeatureFlagStrategiesValidator < ActiveModel::EachValidator
  STRATEGY_DEFAULT = 'default'.freeze
  STRATEGY_GRADUALROLLOUTUSERID = 'gradualRolloutUserId'.freeze

  def validate_each(record, attribute, value)
    return unless value

    if value.is_a?(Array) && value.all? { |s| s.is_a?(Hash) }
      value.each do |strategy|
        strategy_validations(record, attribute, strategy)
      end
    else
      record.errors.add(attribute, 'must be an array of strategy hashes')
    end
  end

  private

  def strategy_validations(record, attribute, strategy)
    case strategy['name']
    when STRATEGY_DEFAULT
      default_parameters_validation(record, attribute, strategy)
    when STRATEGY_GRADUALROLLOUTUSERID
      gradual_rollout_user_id_parameters_validation(record, attribute, strategy)
    else
      record.errors.add(attribute, 'strategy name is invalid')
    end
  end

  def gradual_rollout_user_id_parameters_validation(record, attribute, strategy)
    percentage = strategy.dig('parameters', 'percentage')
    group_id = strategy.dig('parameters', 'groupId')

    unless percentage.is_a?(String) && percentage.match(/\A[1-9]?[0-9]\z|\A100\z/)
      record.errors.add(attribute, 'percentage must be a string between 0 and 100 inclusive')
    end

    unless group_id.is_a?(String) && group_id.match(/\A[a-z]{1,32}\z/)
      record.errors.add(attribute, 'groupId parameter is invalid')
    end
  end

  def default_parameters_validation(record, attribute, strategy)
    unless strategy['parameters'] == {}
      record.errors.add(attribute, 'parameters must be empty for default strategy')
    end
  end
end
