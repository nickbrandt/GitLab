# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::RackAttack, :aggregate_failures do
  describe '.configure' do
    let(:fake_rack_attack) { class_double("Rack::Attack") }
    let(:fake_rack_attack_request) { class_double("Rack::Attack::Request") }

    before do
      stub_const("Rack::Attack", fake_rack_attack)
      stub_const("Rack::Attack::Request", fake_rack_attack_request)

      allow(fake_rack_attack).to receive(:throttled_response=)
      allow(fake_rack_attack).to receive(:throttle)
      allow(fake_rack_attack).to receive(:track)
      allow(fake_rack_attack).to receive(:safelist)
      allow(fake_rack_attack).to receive(:blocklist)
    end

    it 'adds the incident management throttle' do
      described_class.configure(fake_rack_attack)

      expect(fake_rack_attack).to have_received(:throttle)
        .with('throttle_incident_management_notification_web', Gitlab::Throttle.authenticated_web_options)
    end
  end

  describe '.throttled_response_headers' do
    where(:match_data, :headers) do
      [
        [
          {
            discriminator: '127.0.0.1',
            count: 3700,
            period: 1.hour,
            limit: 3600,
            epoch_time: Time.utc(2021, 1, 5, 10, 29, 30).to_i
          },
          {
            'RateLimit-Limit' => '60',
            'RateLimit-Observed' => '3700',
            'RateLimit-Remaining' => '0',
            'RateLimit-Reset' => '1830',
            'RateLimit-ResetTime' => 'Tue, 05 Jan 2021 11:00:00 GMT',
            'Retry-After' => '1830'
          }
        ],
        [
          {
            discriminator: '127.0.0.1',
            count: 3700,
            period: 1.hour,
            limit: 3600,
            epoch_time: Time.utc(2021, 1, 5, 10, 59, 59).to_i
          },
          {
            'RateLimit-Limit' => '60',
            'RateLimit-Observed' => '3700',
            'RateLimit-Remaining' => '0',
            'RateLimit-Reset' => '1',
            'RateLimit-ResetTime' => 'Tue, 05 Jan 2021 11:00:00 GMT',
            'Retry-After' => '1'
          }
        ],
        [
          {
            discriminator: '127.0.0.1',
            count: 3700,
            period: 1.hour,
            limit: 3600,
            epoch_time: Time.utc(2021, 1, 5, 10, 0, 0).to_i
          },
          {
            'RateLimit-Limit' => '60',
            'RateLimit-Observed' => '3700',
            'RateLimit-Remaining' => '0',
            'RateLimit-Reset' => '3600',
            'RateLimit-ResetTime' => 'Tue, 05 Jan 2021 11:00:00 GMT',
            'Retry-After' => '3600'
          }
        ],
        [
          {
            discriminator: '127.0.0.1',
            count: 3700,
            period: 1.hour,
            limit: 3600,
            epoch_time: Time.utc(2021, 1, 5, 23, 30, 0).to_i
          },
          {
            'RateLimit-Limit' => '60',
            'RateLimit-Observed' => '3700',
            'RateLimit-Remaining' => '0',
            'RateLimit-Reset' => '1800',
            'RateLimit-ResetTime' => 'Wed, 06 Jan 2021 00:00:00 GMT', # Next day
            'Retry-After' => '1800'
          }
        ],
        [
          {
            discriminator: '127.0.0.1',
            count: 3700,
            period: 1.hour,
            limit: 3400,
            epoch_time: Time.utc(2021, 1, 5, 10, 30, 0).to_i
          },
          {
            'RateLimit-Limit' => '57', # 56.66 requests per minute
            'RateLimit-Observed' => '3700',
            'RateLimit-Remaining' => '0',
            'RateLimit-Reset' => '1800',
            'RateLimit-ResetTime' => 'Tue, 05 Jan 2021 11:00:00 GMT',
            'Retry-After' => '1800'
          }
        ],
        [
          {
            discriminator: '127.0.0.1',
            count: 3700,
            period: 1.hour,
            limit: 3700,
            epoch_time: Time.utc(2021, 1, 5, 10, 30, 0).to_i
          },
          {
            'RateLimit-Limit' => '62', # 61.66 requests per minute
            'RateLimit-Observed' => '3700',
            'RateLimit-Remaining' => '0',
            'RateLimit-Reset' => '1800',
            'RateLimit-ResetTime' => 'Tue, 05 Jan 2021 11:00:00 GMT',
            'Retry-After' => '1800'
          }
        ],
        [
          {
            discriminator: '127.0.0.1',
            count: 3700,
            period: 1.hour,
            limit: 59,
            epoch_time: Time.utc(2021, 1, 5, 10, 30, 0).to_i
          },
          {
            'RateLimit-Limit' => '1', # 0.9833 requests per minute
            'RateLimit-Observed' => '3700',
            'RateLimit-Remaining' => '0',
            'RateLimit-Reset' => '1800',
            'RateLimit-ResetTime' => 'Tue, 05 Jan 2021 11:00:00 GMT',
            'Retry-After' => '1800'
          }
        ],
        [
          {
            discriminator: '127.0.0.1',
            count: 3700,
            period: 1.hour,
            limit: 61,
            epoch_time: Time.utc(2021, 1, 5, 10, 30, 0).to_i
          },
          {
            'RateLimit-Limit' => '2', # 1.016 requests per minute
            'RateLimit-Observed' => '3700',
            'RateLimit-Remaining' => '0',
            'RateLimit-Reset' => '1800',
            'RateLimit-ResetTime' => 'Tue, 05 Jan 2021 11:00:00 GMT',
            'Retry-After' => '1800'
          }
        ],
        [
          {
            discriminator: '127.0.0.1',
            count: 3700,
            period: 15.seconds,
            limit: 10,
            epoch_time: Time.utc(2021, 1, 5, 10, 30, 0).to_i
          },
          {
            'RateLimit-Limit' => '40',
            'RateLimit-Observed' => '3700',
            'RateLimit-Remaining' => '0',
            'RateLimit-Reset' => '15',
            'RateLimit-ResetTime' => 'Tue, 05 Jan 2021 10:30:15 GMT',
            'Retry-After' => '15'
          }
        ],
        [
          {
            discriminator: '127.0.0.1',
            count: 3700,
            period: 27.seconds,
            limit: 10,
            epoch_time: Time.utc(2021, 1, 5, 10, 30, 0).to_i
          },
          {
            'RateLimit-Limit' => '23',
            'RateLimit-Observed' => '3700',
            'RateLimit-Remaining' => '0',
            'RateLimit-Reset' => '27',
            'RateLimit-ResetTime' => 'Tue, 05 Jan 2021 10:30:27 GMT',
            'Retry-After' => '27'
          }
        ]
      ]
    end

    with_them do
      it 'generates accurate throttled headers' do
        expect(described_class.throttled_response_headers(match_data)).to eql(headers)
      end
    end
  end
end
