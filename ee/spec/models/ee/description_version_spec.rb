# frozen_string_literal: true

require 'spec_helper'

describe DescriptionVersion do
  describe 'associations' do
    it { is_expected.to belong_to :epic }
  end

  describe 'validations' do
    it 'is valid when epic_id is set' do
      expect(described_class.new(epic_id: 1)).to be_valid
    end
  end
end
