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

        it 'exposes correct attributes' do
          expect(subject[:type]).to eq('text')
          expect(subject[:name]).to eq('username')
          expect(subject[:title]).to eq('Username or Email')
          expect(subject[:placeholder]).to eq('Use a username for server version and an email for cloud version')
          expect(subject[:required]).to eq(true)
          expect(subject[:choices]).to be_nil
          expect(subject[:help]).to be_nil
          expect(subject[:value]).to eq('jira_username')
        end
      end

      context 'field with type password' do
        let(:field) { service.global_fields.find { |field| field[:name] == 'password' } }

        it 'exposes correct attributes but hides password' do
          expect(subject[:type]).to eq('password')
          expect(subject[:name]).to eq('password')
          expect(subject[:title]).to eq('Password or API token')
          expect(subject[:placeholder]).to eq('Use a password for server version and an API token for cloud version')
          expect(subject[:required]).to eq(true)
          expect(subject[:choices]).to be_nil
          expect(subject[:help]).to be_nil
          expect(subject[:value]).to eq('true')
        end
      end
    end

    context 'EmailsOnPush Service' do
      let(:service) { create(:emails_on_push_service) }

      context 'field with type checkbox' do
        let(:field) { service.global_fields.find { |field| field[:name] == 'send_from_committer_email' } }

        it 'exposes correct attributes' do
          expect(subject[:type]).to eq('checkbox')
          expect(subject[:name]).to eq('send_from_committer_email')
          expect(subject[:title]).to eq('Send from committer')
          expect(subject[:placeholder]).to be_nil
          expect(subject[:required]).to be_nil
          expect(subject[:choices]).to be_nil
          expect(subject[:help]).to include("Send notifications from the committer's email address if the domain is part of the domain GitLab is running on")
          expect(subject[:value]).to eq(true)
        end
      end

      context 'field with type select' do
        let(:field) { service.global_fields.find { |field| field[:name] == 'branches_to_be_notified' } }

        it 'exposes correct attributes' do
          expect(subject[:type]).to eq('select')
          expect(subject[:name]).to eq('branches_to_be_notified')
          expect(subject[:title]).to be_nil
          expect(subject[:placeholder]).to be_nil
          expect(subject[:required]).to be_nil
          expect(subject[:choices]).to eq([['All branches', 'all'], ['Default branch', 'default'], ['Protected branches', 'protected'], ['Default branch and protected branches', 'default_and_protected']])
          expect(subject[:help]).to be_nil
          expect(subject[:value]).to be_nil
        end
      end
    end
  end
end
