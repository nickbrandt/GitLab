# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Show users over license banner', :js do
  include StubRequests

  let_it_be(:admin) { create(:admin) }
  let_it_be(:user) { create(:user) }
  let_it_be(:license_seats_limit) { 10 }

  let_it_be(:license) do
    create(:license, data: build(:gitlab_license, restrictions: { active_user_count: license_seats_limit }).export)
  end

  shared_examples_for "a visible banner" do
    let(:visit_path) { root_dashboard_path }

    it 'shows the banner' do
      visit visit_path

      expect(page).to have_content('Licensed user count exceeded')
    end
  end

  shared_examples_for "a hidden banner" do
    it 'does not show the banner' do
      visit root_dashboard_path

      expect(page).not_to have_content('Licensed user count exceeded')
    end
  end

  before do
    create(:historical_data, date: license.created_at + 1.month, active_user_count: active_user_count)
  end

  context "with users over license" do
    let(:active_user_count) { license_seats_limit + 5 }

    context 'when admin is logged in' do
      before do
        gitlab_sign_in(admin)
      end

      it_behaves_like 'a visible banner'

      context 'when banner was dismissed' do
        before do
          visit root_dashboard_path

          find('.gl-alert-dismiss').click
        end

        it_behaves_like 'a hidden banner'

        context 'when visiting the admin section' do
          it_behaves_like 'a visible banner' do
            let(:visit_path) { admin_users_path }
          end
        end
      end
    end

    context 'when regular user is logged in' do
      before do
        gitlab_sign_in(user)
      end

      it_behaves_like 'a hidden banner'
    end
  end

  context "without users over license" do
    let(:active_user_count) { 1 }

    context 'when admin is logged in' do
      before do
        gitlab_sign_in(admin)
      end

      it_behaves_like 'a hidden banner'
    end

    context 'when regular user is logged in' do
      before do
        gitlab_sign_in(user)
      end

      it_behaves_like 'a hidden banner'
    end
  end
end
