# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::AlertManagement::IncomingEmail::CreateAlertHandler do
  include_context :email_shared_context

  let_it_be(:namespace) { create(:namespace, path: 'gitlabhq') }
  let_it_be(:project) { create(:project, namespace: namespace) }
  let_it_be(:alerts_service) { create(:alerts_service, project: project) }
  let(:user) { User.alert_bot }
  let(:mail) { Mail::Message.new(email_raw) }
  let(:to_email_address) { Gitlab::AlertManagement::IncomingEmail.email_address(project) }
  let(:short_token) { Gitlab::AlertManagement::IncomingEmail.short_token(project) }
  let(:email_raw) { email_fixture('emails/valid_alert.eml') }
  let(:alert_payload) {
    {
      'title' => 'A new alert',
      'description' => 'Alert description'
    }
  }

  before do
    stub_incoming_email_setting(enabled: true, address: 'incoming+%{key}@appmail.adventuretime.ooo')
    stub_config_setting(host: 'localhost')

    allow(Projects::Alerting::NotifyService)
      .to receive(:new).with(project, user, alert_payload)
      .and_call_original
  end

  it 'calls notify service' do
    receiver.execute

    expect(Projects::Alerting::NotifyService)
      .to have_received(:new)
  end

  private

  def email_fixture(path)
    fixture_file(path)
      .gsub('to_email_address', to_email_address)
      .gsub('project_id', project.id.to_s)
      .gsub('project_full_path_slug', project.full_path_slug)
      .gsub('short_token', short_token)
  end
end
