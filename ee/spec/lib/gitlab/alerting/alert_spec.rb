# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Alerting::Alert do
  set(:project) { create(:project) }

  let(:alert) { build(:alerting_alert, project: project, payload: payload) }
  let(:payload) { {} }

  context 'with gitlab alert' do
    let!(:gitlab_alert) { create(:prometheus_alert, project: project) }

    before do
      payload['labels'] = {
        'gitlab_alert_id' => gitlab_alert_id
      }
    end

    context 'with matching gitlab_alert_id' do
      let(:gitlab_alert_id) { gitlab_alert.prometheus_metric_id.to_s }

      it 'loads gitlab_alert' do
        expect(alert.gitlab_alert).to eq(gitlab_alert)
      end

      it 'delegates environment to gitlab_alert' do
        expect(alert.environment).to eq(gitlab_alert.environment)
      end

      it 'is valid' do
        expect(alert).to be_valid
      end
    end

    context 'with unknown gitlab_alert_id' do
      let(:gitlab_alert_id) { 'unknown' }

      it 'cannot load gitlab_alert' do
        expect(alert.gitlab_alert).to be_nil
      end

      it 'is invalid' do
        expect(alert).not_to be_valid
      end
    end
  end

  context 'with empty payload' do
    it 'cannot load gitlab_alert' do
      expect(alert.gitlab_alert).to be_nil
    end
  end
end
