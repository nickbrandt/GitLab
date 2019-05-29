require 'spec_helper'

describe "Admin::Users" do
  include Spec::Support::Helpers::Features::ResponsiveTableHelpers

  let!(:user) do
    create(:omniauth_user, provider: 'twitter', extern_uid: '123456')
  end

  let!(:current_user) { create(:admin, last_activity_on: 5.days.ago) }

  before do
    sign_in(current_user)
  end

  describe "GET /admin/users/:id" do
    describe 'Shared runners quota status' do
      before do
        user.namespace.update(shared_runners_minutes_limit: 500)
      end

      context 'with projects with shared runners enabled' do
        before do
          create(:project, namespace: user.namespace, shared_runners_enabled: true)
        end

        it 'shows quota' do
          visit admin_users_path

          click_link user.name

          expect(page).to have_content('Pipeline minutes quota: 0 / 500')
        end
      end

      context 'without projects with shared runners enabled' do
        before do
          create(:project, namespace: user.namespace, shared_runners_enabled: false)
        end

        it 'does not show quota' do
          visit admin_users_path

          click_link user.name

          expect(page).not_to have_content('Pipeline minutes quota:')
        end
      end
    end
  end

  describe "GET /admin/users/:id/edit" do
    before do
      visit admin_users_path
      click_link "edit_user_#{user.id}"
    end

    describe "Update user account type" do
      before do
        allow_any_instance_of(AuditorUserHelper).to receive(:license_allows_auditor_user?).and_return(true)
        choose "user_access_level_auditor"
        click_button "Save changes"
      end

      it "changes account type to be auditor" do
        user.reload

        expect(user).not_to be_admin
        expect(user).to be_auditor
      end
    end

    describe 'Update shared runners quota' do
      let!(:project) { create(:project, namespace: user.namespace, shared_runners_enabled: true) }

      before do
        fill_in "user_namespace_attributes_shared_runners_minutes_limit", with: "500"
        click_button "Save changes"
      end

      it "shows page with new data" do
        expect(page).to have_content('Pipeline minutes quota: 0 / 500')
      end
    end
  end
end
