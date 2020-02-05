# frozen_string_literal: true

require 'spec_helper'

describe InstancePolicy do
  let(:current_user) { create(:user) }
  let(:user) { create(:user) }

  before do
    stub_licensed_features(security_dashboard: true)
  end

  subject { described_class.new(current_user, [user]) }

  describe 'read_instance_security_dashboard' do
    context 'when the user is not logged in' do
      let(:current_user) { nil }

      it { is_expected.not_to be_allowed(:read_instance_security_dashboard) }
    end

    context 'when the user is logged in' do
      it { is_expected.to be_allowed(:read_instance_security_dashboard) }
    end
  end
end
