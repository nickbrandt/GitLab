# frozen_string_literal: true
require 'spec_helper'

describe Types::Notes::NoteableType do
  describe ".resolve_type" do
    it 'knows the correct type for EE objects' do
      expect(described_class.resolve_type(build(:design), {})).to eq(Types::DesignManagement::DesignType)
    end
  end
end
