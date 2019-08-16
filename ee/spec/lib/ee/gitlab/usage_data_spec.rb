# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::UsageData do
  describe '.uncached_data' do
    context 'when the :usage_activity_by_stage feaure is not enabled' do
      before do
        stub_feature_flags(usage_activity_by_stage: false)
      end

      it 'does not include usage_activity_by_stage data' do
        expect(described_class.uncached_data).not_to include(:usage_activity_by_stage)
      end
    end

    context 'when the :usage_activity_by_stage feature is enabled' do
      it 'includes usage_activity_by_stage data' do
        expect(described_class.uncached_data).to include(:usage_activity_by_stage)
      end

      context 'for manage' do
        it 'includes accurate usage_activity_by_stage data' do
          user = create(:user)
          create(:group_member, user: user)
          create(:key, type: 'LDAPKey', user: user)
          create(:group_member, ldap: true, user: user)

          expect(described_class.uncached_data[:usage_activity_by_stage][:manage]).to eq(groups: 1, ldap_keys: 1, ldap_users: 1)
        end
      end
    end
  end
end
