# frozen_string_literal: true

require 'spec_helper'

describe StatusPage::Pipeline::PostProcessPipeline do
  describe '.filters' do
    let(:expected_filters) do
      [StatusPage::Filter::MentionAnonymizationFilter] +
        ::Banzai::Pipeline::PostProcessPipeline.filters +
        [StatusPage::Filter::ImageFilter]
    end

    subject { described_class.filters }

    it { is_expected.to eq(expected_filters) }
    it { is_expected.to be_frozen }
  end
end
