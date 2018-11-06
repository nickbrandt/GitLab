# frozen_string_literal: true

require 'spec_helper'

describe PreferencesHelper do
  describe '#dashboard_choices' do
    let(:user) { build(:user) }

    before do
      allow(helper).to receive(:current_user).and_return(user)
    end

    context 'when allowed to read operations dashboard' do
      before do
        allow(helper).to receive(:can?).with(user, :read_operations_dashboard) { true }
      end

      it 'does not contain operations dashboard' do
        expect(helper.dashboard_choices).to include(['Operations Dashboard', 'operations'])
      end
    end

    context 'when not allowed to read operations dashboard' do
      before do
        allow(helper).to receive(:can?).with(user, :read_operations_dashboard) { false }
      end

      it 'does not contain operations dashboard' do
        expect(helper.dashboard_choices).not_to include(['Operations Dashboard', 'operations'])
      end
    end
  end
end
