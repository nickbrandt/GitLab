# frozen_string_literal: true

require 'rails_helper'

describe Clusters::Applications::Prometheus do
  describe 'transition to updating' do
    let(:project) { create(:project) }
    let(:cluster) { create(:cluster, projects: [project]) }

    subject { create(:clusters_applications_prometheus, :installed, cluster: cluster) }

    it 'sets last_update_started_at to now' do
      Timecop.freeze do
        expect { subject.make_updating }.to change { subject.reload.last_update_started_at }.to be_within(1.second).of(Time.now)
      end
    end
  end

  context '#updated_since?' do
    let(:cluster) { create(:cluster) }
    let(:prometheus_app) { build(:clusters_applications_prometheus, cluster: cluster) }
    let(:timestamp) { Time.now - 5.minutes }

    around do |example|
      Timecop.freeze { example.run }
    end

    before do
      prometheus_app.last_update_started_at = Time.now
    end

    context 'when app does not have status failed' do
      it 'returns true when last update started after the timestamp' do
        expect(prometheus_app.updated_since?(timestamp)).to be true
      end

      it 'returns false when last update started before the timestamp' do
        expect(prometheus_app.updated_since?(Time.now + 5.minutes)).to be false
      end
    end

    context 'when app has status failed' do
      it 'returns false when last update started after the timestamp' do
        prometheus_app.status = 6

        expect(prometheus_app.updated_since?(timestamp)).to be false
      end
    end
  end

  describe 'alert manager token' do
    subject { create(:clusters_applications_prometheus) }

    context 'when not set' do
      it 'is empty by default' do
        expect(subject.alert_manager_token).to be_nil
        expect(subject.encrypted_alert_manager_token).to be_nil
        expect(subject.encrypted_alert_manager_token_iv).to be_nil
      end

      describe '#generate_alert_manager_token!' do
        it 'generates a token' do
          subject.generate_alert_manager_token!

          expect(subject.alert_manager_token).to match(/\A\h{32}\z/)
        end
      end
    end

    context 'when set' do
      let(:token) { SecureRandom.hex }

      before do
        subject.update!(alert_manager_token: token)
      end

      it 'reads the token' do
        expect(subject.alert_manager_token).to eq(token)
        expect(subject.encrypted_alert_manager_token).not_to be_nil
        expect(subject.encrypted_alert_manager_token_iv).not_to be_nil
      end

      describe '#generate_alert_manager_token!' do
        it 'does not re-generate the token' do
          subject.generate_alert_manager_token!

          expect(subject.alert_manager_token).to eq(token)
        end
      end
    end
  end
end
