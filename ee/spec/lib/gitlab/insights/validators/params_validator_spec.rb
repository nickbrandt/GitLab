# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Insights::Validators::ParamsValidator do
  subject { described_class.new(params).validate! }

  describe ':type' do
    described_class::SUPPORTER_TYPES.each do |type|
      context "with type: '#{type}'" do
        let(:params) do
          { type: type }
        end

        it 'does not raise an error' do
          expect { subject }.not_to raise_error
        end
      end
    end

    context 'with an invalid :type' do
      let(:params) do
        { type: 'unknown' }
      end

      it 'raises an error' do
        expect { subject }.to raise_error(described_class::InvalidTypeError, "Invalid `:type`: `unknown`. Allowed values are #{described_class::SUPPORTER_TYPES}!")
      end
    end
  end
end
