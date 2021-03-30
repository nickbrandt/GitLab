# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ApprovalRules::ApprovalGroupRule do
  subject { build(:approval_group_rule) }

  describe 'validations' do
    it { is_expected.to validate_presence_of(:group) }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name).scoped_to([:group_id, :rule_type]) }
    it { is_expected.to validate_numericality_of(:approvals_required).is_less_than_or_equal_to(100) }
    it { is_expected.to validate_numericality_of(:approvals_required).is_greater_than_or_equal_to(0) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:group).inverse_of(:approval_rules) }
    it { is_expected.to have_and_belong_to_many(:users) }
    it { is_expected.to have_and_belong_to_many(:groups) }
  end

  describe 'any_approver rules' do
    let_it_be(:group) { create(:group) }

    let(:rule) { build(:approval_group_rule, group: group, rule_type: :any_approver) }

    it 'allows to create only one any_approver rule', :aggregate_failures do
      create(:approval_group_rule, group: group, rule_type: :any_approver)

      expect(rule).not_to be_valid
      expect(rule.errors.messages).to eq(rule_type: ['any-approver for the group already exists'])
    end
  end
end
