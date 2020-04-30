# frozen_string_literal: true
require 'spec_helper'

describe EE::NamespacesHelper do
  let!(:admin) { create(:admin) }
  let!(:admin_project_creation_level) { nil }
  let!(:admin_group) do
    create(:group,
           :private,
           project_creation_level: admin_project_creation_level)
  end
  let!(:user) { create(:user) }
  let!(:user_project_creation_level) { nil }
  let!(:user_group) do
    create(:group,
           :private,
           project_creation_level: user_project_creation_level)
  end

  before do
    admin_group.add_owner(admin)
    user_group.add_owner(user)
  end

  describe '#namespace_shared_runner_limits_quota' do
    context "when it's unlimited" do
      before do
        allow(user_group).to receive(:shared_runners_minutes_limit_enabled?).and_return(false)
      end

      it 'returns Unlimited for the limit section' do
        expect(helper.namespace_shared_runner_limits_quota(user_group)).to match(%r{0 / Unlimited})
      end

      it 'returns the proper value for the used section' do
        allow(user_group).to receive(:shared_runners_seconds).and_return(100 * 60)

        expect(helper.namespace_shared_runner_limits_quota(user_group)).to match(%r{100 / Unlimited})
      end
    end

    context "when it's limited" do
      before do
        allow(user_group).to receive(:shared_runners_minutes_limit_enabled?).and_return(true)
        allow(user_group).to receive(:shared_runners_seconds).and_return(100 * 60)

        user_group.update!(shared_runners_minutes_limit: 500)
      end

      it 'returns the proper values for used and limit sections' do
        expect(helper.namespace_shared_runner_limits_quota(user_group)).to match(%r{100 / 500})
      end
    end
  end

  describe '#namespace_extra_shared_runner_limits_quota' do
    context 'when extra minutes are assigned' do
      it 'returns the proper values for used and limit sections' do
        allow(user_group).to receive(:shared_runners_seconds).and_return(50 * 60)
        user_group.update!(extra_shared_runners_minutes_limit: 100)

        expect(helper.namespace_extra_shared_runner_limits_quota(user_group)).to match(%r{50 / 100})
      end
    end

    context 'when extra minutes are not assigned' do
      it 'returns the proper values for used and limit sections' do
        expect(helper.namespace_extra_shared_runner_limits_quota(user_group)).to match(%r{0 / 0})
      end
    end
  end
end
