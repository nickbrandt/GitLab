# frozen_string_literal: true

require 'spec_helper'

describe Releases::Evidence do
  let(:release) { create(:release) }
  let(:summary_json) { described_class.last.summary.to_json }

  describe 'associations' do
    it { is_expected.to belong_to(:release) }
  end
end
