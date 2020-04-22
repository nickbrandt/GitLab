# frozen_string_literal: true

require 'spec_helper'

describe 'layouts/application' do
  let_it_be(:user) { create(:user) }
  let(:show_notification_dot) { false }

  before do
    allow(view).to receive(:experiment_enabled?).and_return(false)
    allow(view).to receive(:session).and_return({})
    allow(view).to receive(:user_signed_in?).and_return(true)
    allow(view).to receive(:current_user).and_return(user)
    allow(view).to receive(:current_user_mode).and_return(Gitlab::Auth::CurrentUserMode.new(user))
    allow(view).to receive(:show_ci_minutes_notification_dot?).and_return(show_notification_dot)
  end

  describe 'layouts/_user_notification_dot' do
    context 'when we show the notification dot' do
      let(:show_notification_dot) { true }

      before do
        allow(Gitlab).to receive(:com?) { true }
      end

      it 'has the notification dot' do
        render

        expect(rendered).to have_css('span', class: 'header-user-notification-dot')
        expect(rendered).to have_selector('[data-track-event="render"]')
      end
    end

    context 'when we do not show the notification dot' do
      it 'does not have the notification dot' do
        render

        expect(rendered).not_to have_css('span', class: 'header-user-notification-dot')
        expect(rendered).not_to have_selector('[data-track-event="render"]')
      end
    end
  end
end
