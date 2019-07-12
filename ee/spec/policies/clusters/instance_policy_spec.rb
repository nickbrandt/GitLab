# frozen_string_literal: true

require 'spec_helper'

describe Clusters::InstancePolicy do
  let(:user) { create(:admin) }
  let(:policy) { described_class.new(user, Clusters::Instance.new) }

  describe 'rules' do
    context 'when admin' do
      it { expect(policy).to be_allowed :read_cluster }
      it { expect(policy).to be_allowed :add_cluster }
      it { expect(policy).to be_allowed :create_cluster }
      it { expect(policy).to be_allowed :update_cluster }
      it { expect(policy).to be_allowed :admin_cluster }
    end

    context 'when not admin' do
      let(:user) { create(:user) }

      it { expect(policy).to be_disallowed :read_cluster }
      it { expect(policy).to be_disallowed :add_cluster }
      it { expect(policy).to be_disallowed :create_cluster }
      it { expect(policy).to be_disallowed :update_cluster }
      it { expect(policy).to be_disallowed :admin_cluster }
    end
  end
end
