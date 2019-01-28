# frozen_string_literal: true

require 'spec_helper'

describe ApprovalProjectRule do
  subject { create(:approval_project_rule) }

  describe '.regular' do
    it 'returns all records' do
      rules = create_list(:approval_project_rule, 2)

      expect(described_class.regular).to contain_exactly(*rules)
    end
  end

  describe '.code_ownerscope' do
    it 'returns nothing' do
      create_list(:approval_project_rule, 2)

      expect(described_class.code_owner).to be_empty
    end
  end

  describe '#regular' do
    it 'returns true' do
      expect(subject.regular).to eq(true)
      expect(subject.regular?).to eq(true)
    end
  end

  describe '#code_owner' do
    it 'returns false' do
      expect(subject.code_owner).to eq(false)
      expect(subject.code_owner?).to eq(false)
    end
  end
end
