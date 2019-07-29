<script>
import { s__ } from '~/locale';
import createFlash from '~/flash';
import Icon from '~/vue_shared/components/icon.vue';
import AlertWidgetForm from './alert_widget_form.vue';
import AlertsService from '../services/alerts_service';
import { alertsValidator, queriesValidator } from '../validators';
import { GlLoadingIcon, GlModal, GlModalDirective } from '@gitlab/ui';

export default {
  components: {
    Icon,
    AlertWidgetForm,
    GlLoadingIcon,
    GlModal,
  },
  directives: {
    GlModal: GlModalDirective,
  },
  props: {
    alertsEndpoint: {
      type: String,
      required: true,
    },
    // { [alertPath]: { alert_attributes } }. Populated from subsequent API calls.
    // Includes only the metrics/alerts to be managed by this widget.
    alertsToManage: {
      type: Object,
      required: false,
      default: () => ({}),
      validator: alertsValidator,
    },
    // [{ metric+query_attributes }]. Represents queries (and alerts) we know about
    // on intial fetch. Essentially used for reference.
    relevantQueries: {
      type: Array,
      required: true,
      validator: queriesValidator,
    },
    modalId: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      service: null,
      errorMessage: null,
      isLoading: false,
      apiAction: 'create',
    };
  },
  computed: {
    alertSummary() {
      return Object.keys(this.alertsToManage)
        .map(this.formatAlertSummary)
        .join(', ');
    },
    alertIcon() {
      return this.hasAlerts ? 'notifications' : 'notifications-off';
    },
    alertStatus() {
      return this.hasAlerts
        ? s__('PrometheusAlerts|Alert set')
        : s__('PrometheusAlerts|No alert set');
    },
    hasAlerts() {
      return Boolean(Object.keys(this.alertsToManage).length);
    },
    formDisabled() {
      return Boolean(this.errorMessage || this.isLoading);
    },
    supportsComputedAlerts() {
      return gon.features && gon.features.prometheusComputedAlerts;
    },
  },
  created() {
    this.service = new AlertsService({ alertsEndpoint: this.alertsEndpoint });
    this.fetchAlertData();
  },
  beforeDestroy() {
    // clean up external event listeners
    document.removeEventListener('click', this.handleOutsideClick);
  },
  methods: {
    fetchAlertData() {
      this.isLoading = true;

      const queriesWithAlerts = this.relevantQueries.filter(query => query.alert_path);

      return Promise.all(
        queriesWithAlerts.map(query =>
          this.service
            .readAlert(query.alert_path)
            .then(alertAttributes => this.setAlert(alertAttributes, query.metricId)),
        ),
      )
        .then(() => {
          this.isLoading = false;
        })
        .catch(() => {
          createFlash(s__('PrometheusAlerts|Error fetching alert'));
          this.isLoading = false;
        });
    },
    setAlert(alertAttributes, metricId) {
      this.$emit('setAlerts', alertAttributes.alert_path, { ...alertAttributes, metricId });
    },
    removeAlert(alertPath) {
      this.$emit('setAlerts', alertPath, null);
    },
    formatAlertSummary(alertPath) {
      const alert = this.alertsToManage[alertPath];
      const alertQuery = this.relevantQueries.find(query => query.metricId === alert.metricId);

      return `${alertQuery.label} ${alert.operator} ${alert.threshold}`;
    },
    hideModal() {
      this.$root.$emit('bv::hide::modal', this.modalId);
    },
    handleSetApiAction(apiAction) {
      this.apiAction = apiAction;
    },
    handleCreate({ operator, threshold, prometheus_metric_id }) {
      const newAlert = { operator, threshold, prometheus_metric_id };
      this.isLoading = true;
      this.service
        .createAlert(newAlert)
        .then(alertAttributes => {
          this.setAlert(alertAttributes, prometheus_metric_id);
          this.isLoading = false;
          this.hideModal();
        })
        .catch(() => {
          this.errorMessage = s__('PrometheusAlerts|Error creating alert');
          this.isLoading = false;
        });
    },
    handleUpdate({ alert, operator, threshold }) {
      const updatedAlert = { operator, threshold };
      this.isLoading = true;
      this.service
        .updateAlert(alert, updatedAlert)
        .then(alertAttributes => {
          this.setAlert(alertAttributes, this.alertsToManage[alert].metricId);
          this.isLoading = false;
          this.hideModal();
        })
        .catch(() => {
          this.errorMessage = s__('PrometheusAlerts|Error saving alert');
          this.isLoading = false;
        });
    },
    handleDelete({ alert }) {
      this.isLoading = true;
      this.service
        .deleteAlert(alert)
        .then(() => {
          this.removeAlert(alert);
          this.isLoading = false;
          this.hideModal();
        })
        .catch(() => {
          this.errorMessage = s__('PrometheusAlerts|Error deleting alert');
          this.isLoading = false;
        });
    },
  },
};
</script>

<template>
  <div class="prometheus-alert-widget dropdown d-flex align-items-center">
    <span v-if="errorMessage" class="alert-error-message"> {{ errorMessage }} </span>
    <span v-else class="alert-current-setting text-secondary">
      <gl-loading-icon v-show="isLoading" :inline="true" />
      {{ alertSummary }}
    </span>
    <button
      ref="dropdownMenuToggle"
      v-gl-modal="modalId"
      :aria-label="alertStatus"
      class="btn btn-sm mx-2 alert-dropdown-button"
      type="button"
    >
      <icon :name="alertIcon" :size="16" aria-hidden="true" />
    </button>

    <alert-widget-form
      ref="widgetForm"
      :disabled="formDisabled"
      :alerts-to-manage="alertsToManage"
      :relevant-queries="relevantQueries"
      :error-message="errorMessage"
      :modal-id="modalId"
      @create="handleCreate"
      @update="handleUpdate"
      @delete="handleDelete"
      @cancel="hideModal"
      @setAction="handleSetApiAction"
    />
  </div>
</template>
