# frozen_string_literal: true

require 'spec_helper'

describe LicenseHelper do
  def stub_default_url_options(host: "localhost", protocol: "http", port: nil, script_name: '')
    url_options = { host: host, protocol: protocol, port: port, script_name: script_name }
    allow(Rails.application.routes).to receive(:default_url_options).and_return(url_options)
  end

  describe '#license_message' do
    let(:license) { double(:license) }
    let(:message_mock) { double(:message_mock) }

    before do
      allow(License).to receive(:current).and_return(license)
    end

    it 'calls another class with args' do
      expect(Gitlab::ExpiringSubscriptionMessage).to receive(:new).with(
        subscribable: license,
        signed_in: true,
        is_admin: false
      ).and_return(message_mock)

      expect(message_mock).to receive(:message)

      license_message(signed_in: true, is_admin: false)
    end
  end

  describe '#api_license_url' do
    it 'returns license API url' do
      stub_default_url_options

      expect(api_license_url(id: 1)).to eq('http://localhost/api/v4/license/1')
    end

    it 'returns license API url with relative url' do
      stub_default_url_options(script_name: '/gitlab')

      expect(api_license_url(id: 1)).to eq('http://localhost/gitlab/api/v4/license/1')
    end
  end

  describe '#current_active_user_count' do
    let(:license) { create(:license) }

    context 'when there is a license' do
      it 'returns License#current_active_users_count' do
        allow(License).to receive(:current).and_return(license)

        expect(license).to receive(:current_active_users_count).and_return(311)
        expect(current_active_user_count).to eq(311)
      end
    end

    context 'when there is NOT a license' do
      it 'returns the number of active users' do
        allow(License).to receive(:current).and_return(nil)

        expect(current_active_user_count).to eq(User.active.count)
      end
    end
  end

  describe '#guest_user_count' do
    let!(:inactive_owner) { create(:user, :inactive, non_guest: true) }
    let!(:inactive_guest) { create(:user, :inactive) }

    context 'when there are no active users' do
      it 'returns 0' do
        expect(guest_user_count).to eq(0)
      end
    end

    context 'when there are active users and none is a guest user' do
      let!(:owner1) { create(:user, non_guest: true) }
      let!(:owner2) { create(:user, non_guest: true) }

      it 'returns 0' do
        expect(guest_user_count).to eq(0)
      end
    end

    context 'when there are active users and some are guest users' do
      let!(:owner) { create(:user, non_guest: true) }
      let!(:guest) { create(:user) }

      it 'returns the count of all active guest users' do
        expect(guest_user_count).to eq(1)
      end
    end

    context 'when there are active users and all are guest users' do
      let!(:guest1) { create(:user) }
      let!(:guest2) { create(:user) }

      it 'returns the count of all active guest users' do
        expect(guest_user_count).to eq(2)
      end
    end
  end

  describe '#maximum_user_count' do
    context 'when current license is set' do
      it 'returns the maximum_user_count for the current license' do
        license = double
        allow(License).to receive(:current).and_return(license)
        count = 5
        allow(license).to receive(:maximum_user_count).and_return(count)

        expect(maximum_user_count).to eq(count)
      end
    end

    context 'when current license is not set' do
      it 'returns 0' do
        allow(License).to receive(:current).and_return(nil)

        expect(maximum_user_count).to eq(0)
      end
    end
  end

  describe '#current_license' do
    let(:license) { create(:license) }

    it 'returns the current license' do
      expect(license).to eq(license)
    end
  end

  describe '#current_license_title' do
    context 'when there is a current license' do
      let!(:license) { create(:license, more_attrs) }
      let(:more_attrs) { {} }

      context 'and it has a custom plan associated to it' do
        let(:more_attrs) { { plan: License::ULTIMATE_PLAN } }

        it 'returns the plans title' do
          expect(current_license_title).to eq('Ultimate')
        end
      end

      context 'and it has the default plan associated to it' do
        it 'returns the plans title' do
          expect(current_license_title).to eq('Starter')
        end
      end
    end

    context 'when there is NOT a current license' do
      before do
        allow(License).to receive(:current).and_return(nil)
      end

      it 'returns default title' do
        expect(current_license_title).to eq('Core')
      end
    end
  end
end
