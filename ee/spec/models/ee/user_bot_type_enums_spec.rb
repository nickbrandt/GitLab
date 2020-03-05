# frozen_string_literal: true

require 'spec_helper'

describe UserBotTypeEnums do
  it 'has no type conflicts between CE and EE', :aggregate_failures do
    described_class.public_methods(false).each do |method_name|
      method = described_class.method(method_name)

      ee_result = method.call
      ce_result = method.super_method.call

      failure_message = "expected #{method} to have no value conflicts, but it has.\n
      Please make sure you are not overriding values.\n
      Actual values: EE #{ee_result}, CE #{ce_result}"

      expect(ee_result).to include(ce_result), failure_message
      expect(ee_result.values).to match_array(ee_result.values.uniq)
    end
  end
end
