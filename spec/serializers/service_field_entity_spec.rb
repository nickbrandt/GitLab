# frozen_string_literal: true

require 'spec_helper'

describe ServiceFieldEntity do
  let(:request) { double('request') }

  subject { described_class.new(field, request: request, service: service).as_json }

  before do
    allow(request).to receive(:service).and_return(service)
  end

  describe '#as_json' do
    context 'Jira Service' do
      let(:service) { create(:jira_service) }

      context 'field with type text' do
        let(:field) { service.global_fields.find { |field| field[:name] == 'username' } }
        let(:expected_hash) do
          {
            type: 'text',
            name: 'username',
            title: 'Username or Email',
            placeholder: 'Use a username for server version and an email for cloud version',
            required: true,
            choices: nil,
            help: nil,
            value: 'jira_username'
          }
        end

        it 'exposes correct attributes' do
          is_expected.to eq(expected_hash)
        end
      end

      context 'field with type password' do
        let(:field) { service.global_fields.find { |field| field[:name] == 'password' } }

        let(:expected_hash) do
          {
            type: 'password',
            name: 'password',
            title: 'Password or API token',
            placeholder: 'Use a password for server version and an API token for cloud version',
            required: true,
            choices: nil,
            help: nil,
            value: 'true'
          }
        end

        it 'exposes correct attributes but hides password' do
          is_expected.to eq(expected_hash)
        end
      end
    end

    context 'EmailsOnPush Service' do
      let(:service) { create(:emails_on_push_service) }

      context 'field with type checkbox' do
        let(:field) { service.global_fields.find { |field| field[:name] == 'send_from_committer_email' } }
        let(:expected_hash) do
          {
            type: 'checkbox',
            name: 'send_from_committer_email',
            title: 'Send from committer',
            placeholder: nil,
            required: nil,
            choices: nil,
            value: true
          }
        end

        it 'exposes correct attributes' do
          is_expected.to include(expected_hash)
          expect(subject[:help]).to include("Send notifications from the committer's email address if the domain is part of the domain GitLab is running on")
        end
      end

      context 'field with type select' do
        let(:field) { service.global_fields.find { |field| field[:name] == 'branches_to_be_notified' } }
        let(:expected_hash) do
          {
            type: 'select',
            name: 'branches_to_be_notified',
            title: nil,
            placeholder: nil,
            required: nil,
            choices: [['All branches', 'all'], ['Default branch', 'default'], ['Protected branches', 'protected'], ['Default branch and protected branches', 'default_and_protected']],
            help: nil,
            value: nil
          }
        end

        it 'exposes correct attributes' do
          is_expected.to eq(expected_hash)
        end
      end
    end
  end
end
