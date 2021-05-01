# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../rubocop/cop/active_model_errors_removed_methods'

RSpec.describe RuboCop::Cop::ActiveModelErrorsRemovedMethods do
  subject(:cop) { described_class.new }

  context 'when calling values' do
    it 'registers an offense' do
      expect_offense(<<~PATTERN)
        user.errors.values.each { |v| v }
        ^^^^^^^^^^^^^^^^^^ Avoid calling errors hash methods. [...]
      PATTERN

      expect_offense(<<~PATTERN)
        user.errors.keys.each { |v| v }
        ^^^^^^^^^^^^^^^^ Avoid calling errors hash methods. [...]
      PATTERN

      expect_offense(<<~PATTERN)
        user.errors.slice.each { |v| v }
        ^^^^^^^^^^^^^^^^^ Avoid calling errors hash methods. [...]
      PATTERN
    end
  end
end
