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

      before do
        allow(License).to receive(:current).and_return(license)
      end

      context 'license is notify admins' do
        before do
          allow(license).to receive(:notify_admins?).and_return(true)
        end

        context 'admin signed in' do
          let(:signed_in) { true }
          let(:is_admin) { true }

          context 'license is trial' do
            before do
              allow(license).to receive(:trial?).and_return(true)
            end

            context 'license expired' do
              let(:expired_date) { Date.parse('2020-03-09') }

              before do
                allow(license).to receive(:expired?).and_return(true)
                allow(license).to receive(:expires_at).and_return(expired_date)
              end

              it 'has a nice subject' do
                allow(license).to receive(:will_block_changes?).and_return(false)

                regex = /Your trial license expired on 2020-03-09\. <a href=\'https?:\/\/.*\/plans\' target=\'_blank\' rel=\'noopener\'>Buy now!<\/a>/

                expect(subject).to match(regex)
              end

              context 'and it will block changes when it expires' do
                before do
                  allow(license).to receive(:will_block_changes?).and_return(true)
                end

                context 'and its currently blocking changes' do
                  before do
                    allow(license).to receive(:block_changes?).and_return(true)
                  end

                  it 'has an expiration blocking message' do
                    regex = <<~HEREDOC.chomp
                      Pushing code and creation of issues and merge requests has been disabled. Upload a new license in the admin area to restore service.
                    HEREDOC

                    expect(subject).to match(regex)
                  end

                  context 'not admin' do
                    let(:is_admin) { false }

                    it 'has an expiration blocking message' do
                      allow(license).to receive(:notify_users?).and_return(true)

                      regex = <<~HEREDOC.chomp
                        Pushing code and creation of issues and merge requests has been disabled. Ask an admin to upload a new license to restore service.
                      HEREDOC

                      expect(subject).to match(regex)
                    end
                  end
                end

                context 'and its NOT currently blocking changes' do
                  it 'has an expiration blocking message' do
                    allow(license).to receive(:block_changes?).and_return(false)
                    allow(license).to receive(:block_changes_at).and_return(expired_date)

                    regex = <<~HEREDOC.chomp
                      Pushing code and creation of issues and merge requests will be disabled on 2020-03-09. Upload a new license in the admin area to ensure uninterrupted service.
                    HEREDOC

                    expect(subject).to match(regex)
                  end
                end
              end
            end

            context 'license NOT expired' do
              it 'has a nice subject' do
                allow(license).to receive(:expired?).and_return(false)
                allow(license).to receive(:remaining_days).and_return(4)
                allow(license).to receive(:will_block_changes?).and_return(false)

                regex = /Your trial license will expire in 4 days\. <a href=\'https?:\/\/.*\/plans\' target=\'_blank\' rel=\'noopener\'>Buy now!<\/a>/

                expect(subject).to match(regex)
              end
            end
          end

          context 'license is NOT trial' do
            let(:expired_date) { Date.parse('2020-03-09') }

            before do
              allow(license).to receive(:trial?).and_return(false)
              allow(license).to receive(:expired?).and_return(true)
              allow(license).to receive(:expires_at).and_return(expired_date)
              allow(license).to receive(:will_block_changes?).and_return(false)
            end

            it 'has a nice subject' do
              regex = <<~HEREDOC.chomp
                Your license expired on 2020-03-09. For renewal instructions <a href='https://docs.gitlab.com/ee/subscriptions/#renew-your-subscription' target='_blank' rel='noopener'>view our Licensing FAQ.</a>
              HEREDOC

              expect(subject).to match(regex)
            end

            it 'does not have buy now link' do
              expect(subject).not_to include('Buy now!')
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
