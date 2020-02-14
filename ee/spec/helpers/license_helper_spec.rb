# frozen_string_literal: true

require 'spec_helper'

describe LicenseHelper do
  def stub_default_url_options(host: "localhost", protocol: "http", port: nil, script_name: '')
    url_options = { host: host, protocol: protocol, port: port, script_name: script_name }
    allow(Rails.application.routes).to receive(:default_url_options).and_return(url_options)
  end

  describe '#license_message' do
    context 'license installed' do
      subject { license_message(signed_in: true, is_admin: false) }

      let(:license) { double('License') }
      let(:faq_link_regex) { /For renewal instructions <a href.*>view our Licensing FAQ\.<\/a>/ }

      before do
        allow(License).to receive(:current).and_return(license)
        allow(license).to receive(:notify_users?).and_return(true)
        allow(license).to receive(:expired?).and_return(false)
        allow(license).to receive(:remaining_days).and_return(4)
      end

      it 'does NOT have a license faq link if license is a trial' do
        allow(license).to receive(:trial?).and_return(true)

        expect(subject).not_to match(faq_link_regex)
      end

      it 'has license faq link if license is not a trial' do
        allow(license).to receive(:trial?).and_return(false)

        expect(subject).to match(faq_link_regex)
      end
    end

    context 'no license installed' do
      before do
        allow(License).to receive(:current).and_return(nil)
      end

      context 'admin user' do
        let(:is_admin) { true }

        it 'displays correct error message for admin user' do
          expect(license_message(signed_in: true, is_admin: is_admin)).to be_blank
        end
      end

      context 'normal user' do
        let(:is_admin) { false }

        it 'displays correct error message for normal user' do
          expect(license_message(signed_in: true, is_admin: is_admin)).to be_blank
        end
      end
    end
  end

  describe '#api_licenses_url' do
    it 'returns licenses API url' do
      stub_default_url_options

      expect(api_licenses_url).to eq('http://localhost/api/v4/licenses')
    end

    it 'returns licenses API url with relative url' do
      stub_default_url_options(script_name: '/gitlab')

      expect(api_licenses_url).to eq('http://localhost/gitlab/api/v4/licenses')
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
    it 'returns the number of active guest users' do
      expect(guest_user_count).to eq(User.active.count - User.active.excluding_guests.count)
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
end
