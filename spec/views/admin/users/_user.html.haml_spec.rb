# frozen_string_literal: true

require 'spec_helper'

describe 'admin/users/_user' do
  before do
    allow(view).to receive(:user).and_return(user)
  end

  describe 'internal users' do
    describe 'when showing a `Ghost User`' do
      let(:user) { create(:user, ghost: true) }

      it 'does not render action buttons' do
        render

        expect(rendered).not_to have_selector('.table-action-buttons')
      end
    end

    describe 'when showing a `Bot User`' do
      let(:user) { create(:user, bot_type: :alert_bot) }

      it 'does not render action buttons' do
        render

        expect(rendered).not_to have_selector('.table-action-buttons')
      end
    end
  end

  describe 'when showing an external user' do
    let(:user) { create(:user) }

    it 'renders action buttons' do
      render

      expect(rendered).to have_selector('.table-action-buttons')
    end
  end
end
