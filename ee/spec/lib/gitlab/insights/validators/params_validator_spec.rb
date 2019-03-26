# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Insights::Validators::ParamsValidator do
  subject { described_class.new(params).validate! }

  describe ':chart_type' do
    described_class::SUPPORTER_CHART_TYPES.each do |chart_type|
      context "with chart_type: '#{chart_type}'" do
        let(:params) do
          { chart_type: chart_type }
        end

        it 'does not raise an error' do
          expect { subject }.not_to raise_error
        end
      end
    end

    context 'with an invalid :chart_type' do
      let(:params) do
        { chart_type: 'unknown' }
      end

      it 'raises an error' do
        expect { subject }.to raise_error(described_class::InvalidChartTypeError, "Invalid `:chart_type`: `unknown`. Allowed values are #{described_class::SUPPORTER_CHART_TYPES}!")
      end
    end
  end
end
