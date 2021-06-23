# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SyncSeatLinkRequestWorker, type: :worker do
  describe '#perform' do
    subject(:sync_seat_link) do
      described_class.new.perform('2020-01-01T01:20:12+02:00', '123', 5, 4)
    end

    let(:seat_link_url) { [EE::SUBSCRIPTIONS_URL, '/api/v1/seat_links'].join }

    it 'makes an HTTP POST request with passed params' do
      stub_request(:post, seat_link_url).to_return(status: 200)

      sync_seat_link

      expect(WebMock).to have_requested(:post, seat_link_url).with(
        headers: { 'Content-Type' => 'application/json' },
        body: {
          gitlab_version: Gitlab::VERSION,
          timestamp: '2019-12-31T23:20:12Z',
          date: '2019-12-31',
          license_key: '123',
          max_historical_user_count: 5,
          billable_users_count: 4,
          hostname: Gitlab.config.gitlab.host,
          instance_id: Gitlab::CurrentSettings.uuid,
          license_md5: ::License.current.md5
        }.to_json
      )
    end

    context 'when response contains a license' do
      let(:license_key) { build(:gitlab_license, :cloud).export }
      let(:body) { { success: true, license: license_key }.to_json }

      before do
        stub_request(:post, seat_link_url).to_return(
          status: 200,
          body: body,
          headers: { content_type: 'application/json' }
        )
        allow(License).to receive(:current).and_return(current_license)
      end

      shared_examples 'successful license creation' do
        it 'persists the new license' do
          expect { sync_seat_link }.to change(License, :count).by(1)
          expect(License.last).to have_attributes(
            data: license_key,
            cloud: true
          )
        end
      end

      context 'when there is no previous license' do
        let(:current_license) { nil }

        it_behaves_like 'successful license creation'
      end

      context 'when there is a previous license' do
        context 'when it is a cloud license' do
          let(:current_license) { create(:license, cloud: true) }

          it 'persists the new license and deletes any existing cloud licenses' do
            previous_license = create(:license, cloud: true)

            expect { sync_seat_link }.to change(License.cloud, :count).to(1)

            expect(License.last).to have_attributes(data: license_key, cloud: true)
            expect(License.cloud).not_to include(previous_license, current_license)
          end

          context 'when persisting fails' do
            let(:license_key) { 'invalid-key' }

            it 'does not delete the current license and logs error' do
              expect(Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception).and_call_original

              expect { sync_seat_link }.to raise_error
              expect(License).to exist(current_license.id)
            end
          end

          context 'when deleting fails' do
            it 'does not create a new license and logs error' do
              last_license = License.last

              relation = instance_double(ActiveRecord::Relation)
              allow(License).to receive(:cloud).and_return(relation)
              allow(relation).to receive(:delete_all).and_raise

              expect(Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception).and_call_original

              expect { sync_seat_link }.to raise_error
              expect(License.last).to eq(last_license)
            end
          end
        end

        context 'when it is not a cloud license' do
          let(:current_license) { create(:license) }

          it_behaves_like 'successful license creation'
        end
      end
    end

    context 'with old date format string' do
      subject(:sync_seat_link) do
        described_class.new.perform('2020-01-01', '123', 5, 4)
      end

      it 'makes an HTTP POST request with passed params' do
        stub_request(:post, seat_link_url).to_return(status: 200)

        sync_seat_link

        expect(WebMock).to have_requested(:post, seat_link_url).with(
          headers: { 'Content-Type' => 'application/json' },
          body: {
            gitlab_version: Gitlab::VERSION,
            timestamp: '2020-01-01T00:00:00Z',
            date: '2020-01-01',
            license_key: '123',
            max_historical_user_count: 5,
            billable_users_count: 4,
            hostname: Gitlab.config.gitlab.host,
            instance_id: Gitlab::CurrentSettings.uuid,
            license_md5: ::License.current.md5
          }.to_json
        )
      end
    end

    context 'when response contains reconciliation dates' do
      let(:body) { { success: true, next_reconciliation_date: today.to_s, display_alert_from: (today - 7.days).to_s }.to_json }
      let(:today) { Date.current }

      before do
        stub_request(:post, seat_link_url).to_return(
          status: 200,
          body: body,
          headers: { content_type: 'application/json' }
        )
      end

      it 'saves the reconciliation dates' do
        sync_seat_link
        upcoming_reconciliation = GitlabSubscriptions::UpcomingReconciliation.next

        expect(upcoming_reconciliation.next_reconciliation_date).to eq(today)
        expect(upcoming_reconciliation.display_alert_from).to eq(today - 7.days)
      end

      context 'when an upcoming_reconciliation already exists' do
        it 'updates the upcoming_reconciliation' do
          create(:upcoming_reconciliation, :self_managed, next_reconciliation_date: today + 2.days, display_alert_from: today + 1.day)

          sync_seat_link

          upcoming_reconciliation = GitlabSubscriptions::UpcomingReconciliation.next

          expect(upcoming_reconciliation.next_reconciliation_date).to eq(today)
          expect(upcoming_reconciliation.display_alert_from).to eq(today - 7.days)
        end
      end
    end

    shared_examples 'unsuccessful request' do
      context 'when the request is not successful' do
        before do
          stub_request(:post, seat_link_url)
            .to_return(status: 400, body: '{"success":false,"error":"Bad Request"}')
        end

        it 'raises an error with the expected message' do
          expect { sync_seat_link }.to raise_error(
            described_class::RequestError,
            'Seat Link request failed! Code:400 Body:{"success":false,"error":"Bad Request"}'
          )
        end
      end
    end

    it_behaves_like 'unsuccessful request'
  end
end
