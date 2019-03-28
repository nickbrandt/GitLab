# frozen_string_literal: true

require 'spec_helper'

describe NamespacePolicy do
  let(:owner) { create(:user) }
  let(:namespace) { create(:namespace, owner: owner) }
  let(:owner_permissions) { [:create_projects, :admin_namespace, :read_namespace] }

  subject { described_class.new(current_user, namespace) }

  context 'auditor' do
    let(:current_user) { create(:user, :auditor) }

    context 'owner' do
      let(:namespace) { create(:namespace, owner: current_user) }

      it { is_expected.to be_allowed(*owner_permissions) }
    end

    context 'non-owner' do
      it { is_expected.to be_disallowed(*owner_permissions) }
    end
  end
end
