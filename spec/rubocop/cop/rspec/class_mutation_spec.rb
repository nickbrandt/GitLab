# frozen_string_literal: true

require 'spec_helper'

require_relative '../../../../rubocop/cop/rspec/class_mutation'

describe RuboCop::Cop::RSpec::ClassMutation do
  subject(:cop) { described_class.new }

  let(:blacklisted_methods) { described_class::BLACKLISTED_METHODS }

  context 'when calling blacklisted class methods' do
    it 'registers an offence for top-level classes' do
      blacklisted_methods.each do |method|
        inspect_source("Model.#{method} { nil }")
      end

      expect(cop.offenses.size).to eq(blacklisted_methods.size)
    end

    it 'registers an offence for namespaced classes' do
      blacklisted_methods.each do |method|
        inspect_source("Gitlab::Model.#{method} { nil }")
      end

      expect(cop.offenses.size).to eq(blacklisted_methods.size)
    end

    it 'does not register an offence for other methods' do
      inspect_source("Model.not_blacklisted(42)")

      expect(cop.offenses).to be_empty
    end
  end
end
