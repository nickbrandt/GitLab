# frozen_string_literal: true

require 'spec_helper'

describe Admin::ApplicationSettingsController do
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
          elasticsearch_url: 'http://my-elastic.search:9200',
          elasticsearch_indexing: true,
          elasticsearch_aws: true,
          elasticsearch_aws_access_key: 'elasticsearch_aws_access_key',
          elasticsearch_aws_secret_access_key: 'elasticsearch_aws_secret_access_key',
          elasticsearch_aws_region: 'elasticsearch_aws_region',
          elasticsearch_search: true,
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

      expect(response).to redirect_to(admin_application_settings_path)
      settings.except(:elasticsearch_url, :repository_size_limit).each do |setting, value|
        expect(ApplicationSetting.current.public_send(setting)).to eq(value)
      end
      expect(ApplicationSetting.current.repository_size_limit).to eq(settings[:repository_size_limit].megabytes)
      expect(ApplicationSetting.current.elasticsearch_url).to contain_exactly(settings[:elasticsearch_url])
    end

    context 'elasticsearch_aws_secret_access_key setting is blank' do
      let(:settings) do
        {
          elasticsearch_aws_access_key: 'elasticsearch_aws_access_key',
          elasticsearch_aws_secret_access_key: ''
        }
      end

      it 'does not update the elasticsearch_aws_secret_access_key setting' do
        expect { put :update, params: { application_setting: settings } }
          .not_to change { ApplicationSetting.current.reload.elasticsearch_aws_secret_access_key }
      end
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

    it 'updates repository_size_limit' do
      put :update, params: { application_setting: { repository_size_limit: '100' } }

      expect(response).to redirect_to(admin_application_settings_path)
      expect(response).to set_flash[:notice].to('Application settings saved successfully')
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

    describe 'GET #geo_redirection' do
      subject { get :geo_redirection }

      it 'redirects the user to the admin_geo_settings_url' do
        subject

        expect(response).to redirect_to(admin_geo_settings_url)
      end

      it 'fires a notice about the redirection' do
        subject

        expect(response).to set_flash[:notice]
      end
    end
  end
end
