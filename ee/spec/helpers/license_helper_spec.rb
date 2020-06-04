# frozen_string_literal: true

require 'spec_helper'

RSpec.describe LicenseHelper do
  def stub_default_url_options(host: "localhost", protocol: "http", port: nil, script_name: '')
    url_options = { host: host, protocol: protocol, port: port, script_name: script_name }
    allow(Rails.application.routes).to receive(:default_url_options).and_return(url_options)
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

  describe '#current_license_title' do
    context 'when there is a current license' do
      it 'returns the plan titleized if it has a plan associated to it' do
        custom_plan = 'custom plan'
        license = double('License', plan: custom_plan)
        allow(License).to receive(:current).and_return(license)

        expect(current_license_title).to eq(custom_plan.titleize)
      end

      it 'returns the default title if it does not have a plan associated to it' do
        license = double('License', plan: nil)
        allow(License).to receive(:current).and_return(license)

        expect(current_license_title).to eq('Core')
      end
    end

    context 'when there is NOT a current license' do
      it 'returns the default title' do
        allow(License).to receive(:current).and_return(nil)

        expect(current_license_title).to eq('Core')
      end
    end
  end

  describe '#seats_calculation_message' do
    subject { seats_calculation_message(license) }

    context 'with a license' do
      let(:license) { double("License", 'exclude_guests_from_active_count?' => exclude_guests) }

      context 'and guest are excluded from the active count' do
        let(:exclude_guests) { true }

        it 'returns a tag with the message' do
          expect(subject).to eq("<p>Users with a Guest role or those who don&#39;t belong to a Project or Group will not use a seat from your license.</p>")
        end
      end

      context 'and guest are NOT excluded from the active count' do
        let(:exclude_guests) { false }

        it 'returns nil' do
          expect(subject).to be_blank
        end
      end
    end

    context 'when the license is blank' do
      let(:license) { nil }

      it 'returns nil' do
        expect(subject).to be_blank
      end
    end
  end
end
