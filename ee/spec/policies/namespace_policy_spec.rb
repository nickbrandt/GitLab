# frozen_string_literal: true

require 'spec_helper'

describe NamespacePolicy do
  let(:owner) { build_stubbed(:user) }
  let(:namespace) { build_stubbed(:namespace, owner: owner) }
  let(:owner_permissions) { [:create_projects, :admin_namespace, :read_namespace] }

  subject { described_class.new(current_user, namespace) }

  context 'auditor' do
    let(:current_user) { build_stubbed(:user, :auditor) }

    context 'owner' do
      let(:namespace) { build_stubbed(:namespace, owner: current_user) }

      it { is_expected.to be_allowed(*owner_permissions) }
    end

    context 'non-owner' do
      it { is_expected.to be_disallowed(*owner_permissions) }
    end
  end

  describe 'create_jira_connect_subscription' do
    context 'admin' do
      let(:current_user) { build_stubbed(:admin) }

      it { is_expected.to be_allowed(:create_jira_connect_subscription) }
    end

    context 'owner' do
      let(:current_user) { owner }

      it { is_expected.to be_allowed(:create_jira_connect_subscription) }
    end

    context 'other user' do
      let(:current_user) { build_stubbed(:user) }

      it { is_expected.to be_disallowed(:create_jira_connect_subscription) }
    end
  end
end
