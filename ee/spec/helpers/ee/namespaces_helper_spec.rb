# frozen_string_literal: true
require 'spec_helper'

describe EE::NamespacesHelper, :postgresql do
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
  let!(:subgroup1) do
    create(:group,
           :private,
           parent: admin_group,
           project_creation_level: nil)
  end
  let!(:subgroup2) do
    create(:group,
           :private,
           parent: admin_group,
           project_creation_level: ::EE::Gitlab::Access::DEVELOPER_MAINTAINER_PROJECT_ACCESS)
  end
  let!(:subgroup3) do
    create(:group,
           :private,
           parent: admin_group,
           project_creation_level: ::EE::Gitlab::Access::MAINTAINER_PROJECT_ACCESS)
  end

  before do
    admin_group.add_owner(admin)
    user_group.add_owner(user)
  end

  describe '#namespaces_options' do
    describe 'include_groups_with_developer_maintainer_access parameter' do
      context 'when DEVELOPER_MAINTAINER_PROJECT_ACCESS is set for a project' do
        let!(:admin_project_creation_level) { ::EE::Gitlab::Access::DEVELOPER_MAINTAINER_PROJECT_ACCESS }

        it 'returns groups where user is a developer' do
          allow(helper).to receive(:current_user).and_return(user)
          stub_application_setting(default_project_creation: ::EE::Gitlab::Access::MAINTAINER_PROJECT_ACCESS)
          admin_group.add_user(user, GroupMember::DEVELOPER)

          options = helper.namespaces_options_with_developer_maintainer_access

          expect(options).to include(admin_group.name)
          expect(options).not_to include(subgroup1.name)
          expect(options).to include(subgroup2.name)
          expect(options).not_to include(subgroup3.name)
          expect(options).to include(user_group.name)
          expect(options).to include(user.name)
        end
      end

      context 'when DEVELOPER_MAINTAINER_PROJECT_ACCESS is set globally' do
        it 'return groups where default is not overridden' do
          allow(helper).to receive(:current_user).and_return(user)
          stub_application_setting(default_project_creation: ::EE::Gitlab::Access::DEVELOPER_MAINTAINER_PROJECT_ACCESS)
          admin_group.add_user(user, GroupMember::DEVELOPER)

          options = helper.namespaces_options_with_developer_maintainer_access

          expect(options).to include(admin_group.name)
          expect(options).to include(subgroup1.name)
          expect(options).to include(subgroup2.name)
          expect(options).not_to include(subgroup3.name)
          expect(options).to include(user_group.name)
          expect(options).to include(user.name)
        end
      end
    end
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
        allow(user_group).to receive(:shared_runners_minutes).and_return(100)

        expect(helper.namespace_shared_runner_limits_quota(user_group)).to match(%r{100 / Unlimited})
      end
    end

    context "when it's limited" do
      before do
        allow(user_group).to receive(:shared_runners_minutes_limit_enabled?).and_return(true)
        allow(user_group).to receive(:shared_runners_minutes).and_return(100)

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
        allow(user_group).to receive(:extra_shared_runners_minutes).and_return(50)
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
