# frozen_string_literal: true

require 'spec_helper'

describe ApprovalProjectRule do
  subject { create(:approval_project_rule) }

  describe 'validations' do
    it { is_expected.to validate_uniqueness_of(:name).scoped_to(:project_id) }
  end

  describe '.regular' do
    it 'returns non-report_approver records' do
      rules = create_list(:approval_project_rule, 2)
      create(:approval_project_rule, :security_report)

      expect(described_class.regular).to contain_exactly(*rules)
    end
  end

  describe '.regular_or_any_approver scope' do
    it 'returns regular or any-approver rules' do
      any_approver_rule = create(:approval_project_rule, rule_type: :any_approver)
      regular_rule = create(:approval_project_rule)
      create(:approval_project_rule, :security_report)

      expect(described_class.regular_or_any_approver).to(
        contain_exactly(any_approver_rule, regular_rule)
      )
    end
  end

  describe '.code_owner scope' do
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

  describe "#apply_report_approver_rules_to" do
    let(:project) { merge_request.target_project }
    let(:merge_request) { create(:merge_request) }
    let(:user) { create(:user) }
    let(:group) { create(:group) }

    before do
      subject.users << user
      subject.groups << group
    end

    ApprovalProjectRule::REPORT_TYPES_BY_DEFAULT_NAME.each do |name, value|
      context "when the project rule is for a `#{name}`" do
        subject { create(:approval_project_rule, value, :requires_approval, project: project) }

        let!(:result) { subject.apply_report_approver_rules_to(merge_request) }

        specify { expect(merge_request.reload.approval_rules).to match_array([result]) }
        specify { expect(result.users).to match_array([user]) }
        specify { expect(result.groups).to match_array([group]) }
      end
    end
  end

  describe "validation" do
    let(:project_approval_rule) { create(:approval_project_rule) }
    let(:license_compliance_rule) { create(:approval_project_rule, :license_management) }
    let(:vulnerability_check_rule) { create(:approval_project_rule, :security) }

    context "when creating a new rule" do
      specify { expect(project_approval_rule).to be_valid }
      specify { expect(license_compliance_rule).to be_valid }
      specify { expect(vulnerability_check_rule).to be_valid }
    end

    context "when attempting to edit the name of the rule" do
      subject { project_approval_rule }

      before do
        subject.name = SecureRandom.uuid
      end

      specify { expect(subject).to be_valid }

      context "with a `License-Check` rule" do
        subject { license_compliance_rule }

        specify { expect(subject).not_to be_valid }
        specify { expect { subject.valid? }.to change { subject.errors[:name].present? } }
      end

      context "with a `Vulnerability-Check` rule" do
        subject { vulnerability_check_rule }

        specify { expect(subject).to be_valid }
      end
    end
  end

  context 'any_approver rules' do
    let(:project) { create(:project) }
    let(:rule) { build(:approval_project_rule, project: project, rule_type: :any_approver) }

    it 'creating more than one any_approver rule raises an error' do
      create(:approval_project_rule, project: project, rule_type: :any_approver)

      expect { rule.save }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end
end
