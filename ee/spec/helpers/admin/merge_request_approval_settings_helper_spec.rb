# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::MergeRequestApprovalSettingsHelper do
  describe '#show_compliance_merge_request_approval_settings?' do
    using RSpec::Parameterized::TableSyntax

    subject { helper.show_compliance_merge_request_approval_settings? }

    where(:feature_flag, :licensed, :result) do
      true  | true  | true
      true  | false | false
      false | true  | false
      false | false | false
    end

    with_them do
      before do
        stub_feature_flags(admin_compliance_merge_request_approval_settings: feature_flag)
        stub_licensed_features(admin_merge_request_approvers_rules: licensed)
      end

      it { is_expected.to eq(result) }
    end
  end
end
