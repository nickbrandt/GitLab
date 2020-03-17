# frozen_string_literal: true

require 'spec_helper'

describe LicenseHelper do
  def stub_default_url_options(host: "localhost", protocol: "http", port: nil, script_name: '')
    url_options = { host: host, protocol: protocol, port: port, script_name: script_name }
    allow(Rails.application.routes).to receive(:default_url_options).and_return(url_options)
  end

  describe '#license_message' do
    subject { license_message(signed_in: signed_in, is_admin: is_admin) }

    context 'license installed' do
      let(:license) { double(:license) }
      let(:expired_date) { Time.utc(2020, 3, 9, 10) }
      let(:today) { Time.utc(2020, 3, 7, 10) }

      before do
        allow(License).to receive(:current).and_return(license)
        allow(license).to receive(:plan).and_return('ultimate')
        allow(license).to receive(:expires_at).and_return(expired_date)
      end

      context 'license is notify admins' do
        before do
          allow(license).to receive(:notify_admins?).and_return(true)
        end

        context 'admin signed in' do
          let(:signed_in) { true }
          let(:is_admin) { true }

          context 'license expired' do
            let(:expired_date) { Time.utc(2020, 3, 9).to_date }

            before do
              allow(license).to receive(:expired?).and_return(true)
              allow(license).to receive(:expires_at).and_return(expired_date)
            end

            context 'and it will block changes when it expires' do
              before do
                allow(license).to receive(:will_block_changes?).and_return(true)
              end

              context 'and its currently blocking changes' do
                before do
                  allow(license).to receive(:block_changes?).and_return(true)
                  allow(license).to receive(:block_changes_at).and_return(expired_date)
                end

                it 'has a nice subject' do
                  allow(license).to receive(:will_block_changes?).and_return(false)

                  expect(subject).to have_text('Your subscription has been downgraded')
                end

                it 'has an expiration blocking message' do
                  Timecop.freeze(today) do
                    expect(subject).to have_text("You didn't renew your Ultimate subscription so it was downgraded to the GitLab Core Plan")
                  end
                end
              end

              context 'and its NOT currently blocking changes' do
                before do
                  allow(license).to receive(:block_changes?).and_return(false)
                end

                it 'has a nice subject' do
                  allow(license).to receive(:will_block_changes?).and_return(false)

                  expect(subject).to have_text('Your subscription expired!')
                end

                it 'has an expiration blocking message' do
                  allow(license).to receive(:block_changes_at).and_return(expired_date)

                  Timecop.freeze(today) do
                    expect(subject).to have_text('No worries, you can still use all the Ultimate features for now. You have 2 days to renew your subscription.')
                  end
                end
              end
            end
          end

          context 'license NOT expired' do
            before do
              allow(license).to receive(:expired?).and_return(false)
              allow(license).to receive(:remaining_days).and_return(4)
              allow(license).to receive(:will_block_changes?).and_return(true)
              allow(license).to receive(:block_changes_at).and_return(expired_date)
            end

            it 'has a nice subject' do
              expect(subject).to have_text('Your subscription will expire in 4 days')
            end

            it 'has an expiration blocking message' do
              Timecop.freeze(today) do
                expect(subject).to have_text('Your Ultimate subscription will expire on 2020-03-09. After that, you will not to be able to create issues or merge requests as well as many other features.')
              end
            end
          end
        end
      end
    end

    context 'no license installed' do
      let(:license) { nil }
      let(:signed_in) { true }
      let(:is_admin) { true }

      it { is_expected.to be_blank }
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
