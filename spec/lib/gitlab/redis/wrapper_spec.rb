# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Redis::Wrapper do
  describe '.instrumentation_class' do
    it 'raises a NotImplementedError' do
      expect { described_class.instrumentation_class }.to raise_error(NotImplementedError)
    end
  end
end
