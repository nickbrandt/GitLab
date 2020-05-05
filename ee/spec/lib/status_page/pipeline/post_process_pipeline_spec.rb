# frozen_string_literal: true

require 'spec_helper'

describe StatusPage::Pipeline::PostProcessPipeline do
  describe '.filters' do
    subject { described_class.filters }

    it { is_expected.to eq(::Banzai::Pipeline::PostProcessPipeline.filters.push(StatusPage::Filter::ImageFilter)) }
  end
end
