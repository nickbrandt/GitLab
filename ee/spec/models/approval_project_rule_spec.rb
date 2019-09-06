# frozen_string_literal: true

require 'spec_helper'

describe ApprovalProjectRule do
  subject { create(:approval_project_rule) }

  describe 'validations' do
    it 'enforces uniqueness of rule names scoped to a project' do
      new_rule = build(:approval_project_rule, name: subject.name, project: subject.project)

      expect(new_rule).to_not be_valid
    end

    it 'does not enforce uniqueness of rule names across projects' do
      new_rule = build(:approval_project_rule, name: subject.name)

      expect(new_rule).to be_valid
    end
  end

  describe '.regular' do
    it 'returns non-report_approver records' do
      rules = create_list(:approval_project_rule, 2)
      create(:approval_project_rule, :security_report)

      expect(described_class.regular).to contain_exactly(*rules)
    end
  end

  describe '.code_ownerscope' do
    it 'returns nothing' do
      create_list(:approval_project_rule, 2)

      expect(described_class.code_owner).to be_empty
    end
  end

  describe '#regular?' do
    let(:security_approver_rule) { build(:approval_project_rule, :security_report) }

    it 'returns true for regular rules' do
      expect(subject.regular?).to eq(true)
    end

    it 'returns false for report_approver rules' do
      expect(security_approver_rule.regular?). to eq(false)
    end
  end

  describe '#code_owner?' do
    it 'returns false' do
      expect(subject.code_owner?).to eq(false)
    end
  end

  describe '#report_approver?' do
    let(:security_approver_rule) { build(:approval_project_rule, :security_report) }

    it 'returns false for regular rules' do
      expect(subject.report_approver?).to eq(false)
    end

    it 'returns true for report_approver rules' do
      expect(security_approver_rule.report_approver?). to eq(true)
    end
  end

  describe '#rule_type' do
    it 'returns the regular type for regular rules' do
      expect(build(:approval_project_rule).rule_type).to eq('regular')
    end

    it 'returns the report_approver type for security report approvers rules' do
      expect(build(:approval_project_rule, :security_report).rule_type).to eq('report_approver')
    end
  end
end
