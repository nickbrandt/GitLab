# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::ApplicationSettingsController do
  include StubENV

  let(:admin) { create(:admin) }

  before do
    stub_env('IN_MEMORY_APPLICATION_SETTINGS', 'false')
  end

  describe 'PUT #update' do
    before do
      sign_in(admin)
    end

    it 'updates the EE specific application settings' do
      settings = {
          help_text: 'help_text',
          repository_size_limit: 1024,
          shared_runners_minutes: 60,
          geo_status_timeout: 30,
          check_namespace_plan: true,
          authorized_keys_enabled: true,
          slack_app_enabled: true,
          slack_app_id: 'slack_app_id',
          slack_app_secret: 'slack_app_secret',
          slack_app_verification_token: 'slack_app_verification_token',
          allow_group_owners_to_manage_ldap: false,
          lock_memberships_to_ldap: true,
          geo_node_allowed_ips: '0.0.0.0/0, ::/0'
      }

      put :update, params: { application_setting: settings }

      expect(response).to redirect_to(general_admin_application_settings_path)
      settings.except(:repository_size_limit).each do |setting, value|
        expect(ApplicationSetting.current.public_send(setting)).to eq(value)
      end
      expect(ApplicationSetting.current.repository_size_limit).to eq(settings[:repository_size_limit].megabytes)
    end

    shared_examples 'settings for licensed features' do
      it 'does not update settings when licensed feature is not available' do
        stub_licensed_features(feature => false)
        attribute_names = settings.keys.map(&:to_s)

        expect { put :update, params: { application_setting: settings } }
          .not_to change { ApplicationSetting.current.reload.attributes.slice(*attribute_names) }
      end

      it 'updates settings when the feature is available' do
        stub_licensed_features(feature => true)

        put :update, params: { application_setting: settings }

        settings.each do |attribute, value|
          expect(ApplicationSetting.current.public_send(attribute)).to eq(value)
        end
      end
    end

    context 'mirror settings' do
      let(:settings) do
        {
          mirror_max_delay: (Gitlab::Mirror.min_delay_upper_bound / 60) + 1,
          mirror_max_capacity: 200,
          mirror_capacity_threshold: 2
        }
      end

      let(:feature) { :repository_mirrors }

      it_behaves_like 'settings for licensed features'
    end

    context 'default project deletion protection' do
      let(:settings) { { default_project_deletion_protection: true } }
      let(:feature) { :default_project_deletion_protection }

      it_behaves_like 'settings for licensed features'
    end

    context 'updating name disabled for users setting' do
      let(:settings) { { updating_name_disabled_for_users: true } }
      let(:feature) { :disable_name_update_for_users }

      it_behaves_like 'settings for licensed features'
    end

    context 'updating `group_owners_can_manage_default_branch_protection` setting' do
      let(:settings) { { group_owners_can_manage_default_branch_protection: false } }
      let(:feature) { :default_branch_protection_restriction_in_groups }

      it_behaves_like 'settings for licensed features'
    end

    context 'updating npm packages request forwarding setting' do
      let(:settings) { { npm_package_requests_forwarding: true } }
      let(:feature) { :package_forwarding }

      it_behaves_like 'settings for licensed features'
    end

    context 'updating `git_two_factor_session_expiry` setting' do
      before do
        stub_feature_flags(two_factor_for_cli: true)
      end

      let(:settings) { { git_two_factor_session_expiry: 10 } }
      let(:feature) { :git_two_factor_enforcement }

      it_behaves_like 'settings for licensed features'
    end

    context 'updating maintenance mode setting' do
      before do
        stub_feature_flags(maintenance_mode: true)
      end

      let(:settings) do
        {
          maintenance_mode: true,
          maintenance_mode_message: 'GitLab is in maintenance'
        }
      end

      let(:feature) { :geo }

      it_behaves_like 'settings for licensed features'
    end

    context 'project deletion delay' do
      let(:settings) { { deletion_adjourned_period: 6 } }
      let(:feature) { :adjourned_deletion_for_projects_and_groups }

      it_behaves_like 'settings for licensed features'
    end

    context 'additional email footer' do
      let(:settings) { { email_additional_text: 'scary legal footer' } }
      let(:feature) { :email_additional_text }

      it_behaves_like 'settings for licensed features'
    end

    context 'custom project templates settings' do
      let(:group) { create(:group) }
      let(:settings) { { custom_project_templates_group_id: group.id } }
      let(:feature) { :custom_project_templates }

      it_behaves_like 'settings for licensed features'
    end

    context 'merge request approvers rules' do
      let(:settings) do
        {
          disable_overriding_approvers_per_merge_request: true,
          prevent_merge_requests_author_approval: true,
          prevent_merge_requests_committers_approval: true
        }
      end

      let(:feature) { :admin_merge_request_approvers_rules }

      it_behaves_like 'settings for licensed features'
    end

    context 'required instance ci template' do
      let(:settings) { { required_instance_ci_template: 'Auto-DevOps' } }
      let(:feature) { :required_ci_templates }

      it_behaves_like 'settings for licensed features'

      context 'when ApplicationSetting already has a required_instance_ci_template value' do
        before do
          ApplicationSetting.current.update!(required_instance_ci_template: 'Auto-DevOps')
        end

        context 'with a valid value' do
          let(:settings) { { required_instance_ci_template: 'Code-Quality' } }

          it_behaves_like 'settings for licensed features'
        end

        context 'with an empty value' do
          it 'sets required_instance_ci_template as nil' do
            stub_licensed_features(required_ci_templates: true)

            put :update, params: { application_setting: { required_instance_ci_template: '' } }

            expect(ApplicationSetting.current.required_instance_ci_template).to be_nil
          end
        end

        context 'without key' do
          it 'does not set required_instance_ci_template to nil' do
            put :update, params: { application_setting: {} }

            expect(ApplicationSetting.current.required_instance_ci_template).to be == 'Auto-DevOps'
          end
        end
      end
    end

    it 'updates repository_size_limit' do
      put :update, params: { application_setting: { repository_size_limit: '100' } }

      expect(response).to redirect_to(general_admin_application_settings_path)
      expect(controller).to set_flash[:notice].to('Application settings saved successfully')
    end

    it 'does not accept negative repository_size_limit' do
      put :update, params: { application_setting: { repository_size_limit: '-100' } }

      expect(response).to render_template(:general)
      expect(assigns(:application_setting).errors[:repository_size_limit]).to be_present
    end

    it 'does not accept invalid repository_size_limit' do
      put :update, params: { application_setting: { repository_size_limit: 'one thousand' } }

      expect(response).to render_template(:general)
      expect(assigns(:application_setting).errors[:repository_size_limit]).to be_present
    end

    it 'does not accept empty repository_size_limit' do
      put :update, params: { application_setting: { repository_size_limit: '' } }

      expect(response).to render_template(:general)
      expect(assigns(:application_setting).errors[:repository_size_limit]).to be_present
    end

    describe 'verify panel actions' do
      Admin::ApplicationSettingsController::EE_VALID_SETTING_PANELS.each do |valid_action|
        it_behaves_like 'renders correct panels' do
          let(:action) { valid_action }
        end
      end
    end

    it 'updates setting to enforce personal access token expiration' do
      put :update, params: { application_setting: { enforce_pat_expiration: false } }

      expect(response).to redirect_to(general_admin_application_settings_path)
      expect(ApplicationSetting.current.enforce_pat_expiration).to be_falsey
    end

    context 'maintenance mode settings' do
      let(:message) { 'Maintenance mode is on.' }

      before do
        stub_licensed_features(geo: true)
      end

      it "updates maintenance_mode setting" do
        put :update, params: { application_setting: { maintenance_mode: true } }

        expect(response).to redirect_to(general_admin_application_settings_path)
        expect(ApplicationSetting.current.maintenance_mode).to be_truthy
      end

      it "updates maintenance_mode_message setting" do
        put :update, params: { application_setting: { maintenance_mode_message: message } }

        expect(response).to redirect_to(general_admin_application_settings_path)
        expect(ApplicationSetting.current.maintenance_mode_message).to eq(message)
      end

      context 'when update disables maintenance mode' do
        it 'removes maintenance_mode_message setting' do
          put :update, params: { application_setting: { maintenance_mode: false } }

          expect(response).to redirect_to(general_admin_application_settings_path)
          expect(ApplicationSetting.current.maintenance_mode).to be_falsy
          expect(ApplicationSetting.current.maintenance_mode_message).to be_nil
        end
      end

      context 'when update does not disable maintenance mode' do
        it 'does not remove maintenance_mode_message' do
          set_maintenance_mode(message)

          put :update, params: { application_setting: {} }

          expect(ApplicationSetting.current.maintenance_mode_message).to eq(message)
        end
      end

      context 'when updating maintenance_mode_message with empty string' do
        it 'removes maintenance_mode_message' do
          set_maintenance_mode(message)

          put :update, params: { application_setting: { maintenance_mode_message: '' } }

          expect(ApplicationSetting.current.maintenance_mode_message).to eq(nil)
        end
      end
    end
  end

  describe '#advanced_search' do
    before do
      sign_in(admin)
      @request.env['HTTP_REFERER'] = advanced_search_admin_application_settings_path
    end

    context 'advanced search settings' do
      it 'updates the advanced search settings' do
        settings = {
            elasticsearch_url: 'http://my-elastic.search:9200',
            elasticsearch_indexing: false,
            elasticsearch_aws: true,
            elasticsearch_aws_access_key: 'elasticsearch_aws_access_key',
            elasticsearch_aws_secret_access_key: 'elasticsearch_aws_secret_access_key',
            elasticsearch_aws_region: 'elasticsearch_aws_region',
            elasticsearch_search: true
        }

        patch :advanced_search, params: { application_setting: settings }

        expect(response).to redirect_to(advanced_search_admin_application_settings_path)
        settings.except(:elasticsearch_url).each do |setting, value|
          expect(ApplicationSetting.current.public_send(setting)).to eq(value)
        end
        expect(ApplicationSetting.current.elasticsearch_url).to contain_exactly(settings[:elasticsearch_url])
      end
    end

    context 'zero-downtime elasticsearch reindexing' do
      render_views

      let!(:task) { create(:elastic_reindexing_task) }

      it 'assigns last elasticsearch reindexing task' do
        get :advanced_search

        expect(assigns(:last_elasticsearch_reindexing_task)).to eq(task)
        expect(response.body).to include("Reindexing Status: #{task.state}")
      end
    end

    context 'elasticsearch_aws_secret_access_key setting is blank' do
      let(:settings) do
        {
          elasticsearch_aws_access_key: 'elasticsearch_aws_access_key',
          elasticsearch_aws_secret_access_key: ''
        }
      end

      it 'does not update the elasticsearch_aws_secret_access_key setting' do
        expect { patch :advanced_search, params: { application_setting: settings } }
          .not_to change { ApplicationSetting.current.reload.elasticsearch_aws_secret_access_key }
      end
    end
  end

  describe 'GET #seat_link_payload' do
    context 'when a non-admin user attempts a request' do
      before do
        sign_in(create(:user))
      end

      it 'returns a 404 response' do
        get :seat_link_payload, format: :html

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when an admin user attempts a request' do
      let_it_be(:yesterday) { Time.current.utc.yesterday }
      let_it_be(:max_count) { 15 }
      let_it_be(:current_count) { 10 }

      around do |example|
        freeze_time { example.run }
      end

      before_all do
        create(:historical_data, recorded_at: yesterday - 1.day, active_user_count: max_count)
        create(:historical_data, recorded_at: yesterday, active_user_count: current_count)
      end

      before do
        sign_in(admin)
      end

      it 'returns HTML data', :aggregate_failures do
        get :seat_link_payload, format: :html

        expect(response).to have_gitlab_http_status(:ok)

        body = response.body
        expect(body).to start_with('<span id="LC1" class="line" lang="json">')
        expect(body).to include('<span class="nl">"license_key"</span>')
        expect(body).to include("<span class=\"s2\">\"#{yesterday.iso8601}\"</span>")
        expect(body).to include("<span class=\"mi\">#{max_count}</span>")
        expect(body).to include("<span class=\"mi\">#{current_count}</span>")
      end

      it 'returns JSON data', :aggregate_failures do
        get :seat_link_payload, format: :json

        expect(response).to have_gitlab_http_status(:ok)
        expect(response.body).to eq(Gitlab::SeatLinkData.new.to_json)
      end
    end
  end

  def set_maintenance_mode(message)
    ApplicationSetting.current.update!(
      maintenance_mode: true,
      maintenance_mode_message: message
    )
  end
end
