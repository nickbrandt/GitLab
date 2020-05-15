# frozen_string_literal: true

require 'spec_helper'

describe ServiceFieldEntity do
  let(:service) { create(:jira_service) }
  let(:request) { double('request') }

  subject { described_class.new(field, request: request, service: service).as_json }

  before do
    allow(request).to receive(:service).and_return(service)
  end

  describe '#as_json' do
    context 'field with type text' do
      let(:field) { service.global_fields.find { |field| field[:name] == 'username' } }

      it 'exposes correct attributes' do
        expect(subject[:type]).to eq('text')
        expect(subject[:name]).to eq('username')
        expect(subject[:title]).to eq('Username or Email')
        expect(subject[:placeholder]).to eq('Use a username for server version and an email for cloud version')
        expect(subject[:required]).to eq(true)
        expect(subject[:choices]).to eq(nil)
        expect(subject[:help]).to eq(nil)
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
        expect(subject[:choices]).to eq(nil)
        expect(subject[:help]).to eq(nil)
        expect(subject[:value]).to eq('true')
      end
    end
  end
end
