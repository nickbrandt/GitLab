import PrometheusMetrics from 'ee/prometheus_metrics/prometheus_metrics';
import PrometheusAlerts from 'ee/prometheus_alerts';
import initAlertsSettings from 'ee/alerts_service_settings';
import IntegrationSettingsForm from '~/integrations/integration_settings_form';

document.addEventListener('DOMContentLoaded', () => {
  const integrationSettingsForm = new IntegrationSettingsForm('.js-integration-settings-form');
  integrationSettingsForm.init();

  const prometheusSettingsWrapper = document.querySelector('.js-prometheus-metrics-monitoring');
  if (prometheusSettingsWrapper) {
    const prometheusMetrics = new PrometheusMetrics('.js-prometheus-metrics-monitoring');
    if (prometheusMetrics.isServiceActive) {
      prometheusMetrics.loadActiveCustomMetrics();
    } else {
      prometheusMetrics.setNoIntegrationActiveState();
    }
  }

  PrometheusAlerts();

  initAlertsSettings(document.querySelector('.js-alerts-service-settings'));
});
