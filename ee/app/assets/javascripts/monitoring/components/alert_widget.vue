<script>
import { s__ } from '~/locale';
import Icon from '~/vue_shared/components/icon.vue';
import AlertWidgetForm from './alert_widget_form.vue';
import AlertsService from '../services/alerts_service';
import { alertsValidator, queriesValidator } from '../validators';
import { GlLoadingIcon } from '@gitlab/ui';

export default {
  components: {
    Icon,
    AlertWidgetForm,
    GlLoadingIcon,
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
  },
  data() {
    return {
      service: null,
      errorMessage: null,
      isLoading: false,
      isOpen: false,
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
    dropdownTitle() {
      return this.apiAction === 'create'
        ? s__('PrometheusAlerts|Add alert')
        : s__('PrometheusAlerts|Edit alert');
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
  watch: {
    isOpen(open) {
      if (open) {
        document.addEventListener('click', this.handleOutsideClick);
      } else {
        document.removeEventListener('click', this.handleOutsideClick);
      }
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
          this.errorMessage = s__('PrometheusAlerts|Error fetching alert');
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
    handleDropdownToggle() {
      this.isOpen = !this.isOpen;
    },
    handleDropdownClose() {
      this.isOpen = false;
    },
    handleOutsideClick(event) {
      if (
        !this.$refs.dropdownMenu.contains(event.target) &&
        !this.$refs.dropdownMenuToggle.contains(event.target)
      ) {
        this.isOpen = false;
      }
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
          this.handleDropdownClose();
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
          this.handleDropdownClose();
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
          this.handleDropdownClose();
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
    <span v-else class="alert-current-setting">
      <gl-loading-icon v-show="isLoading" :inline="true" />
      {{ alertSummary }}
    </span>
    <button
      ref="dropdownMenuToggle"
      :aria-label="alertStatus"
      class="btn btn-sm alert-dropdown-button"
      type="button"
      @click="handleDropdownToggle"
    >
      <icon :name="alertIcon" :size="16" aria-hidden="true" />
      <icon :size="16" name="arrow-down" aria-hidden="true" class="chevron" />
    </button>
    <div
      ref="dropdownMenu"
      :class="{ show: isOpen, 'h-auto': supportsComputedAlerts }"
      class="dropdown-menu alert-dropdown-menu"
    >
      <div class="dropdown-title m0">
        <span>{{ dropdownTitle }}</span>
        <button
          class="dropdown-title-button dropdown-menu-close"
          type="button"
          aria-label="Close"
          @click="handleDropdownClose"
        >
          <icon :size="12" name="close" aria-hidden="true" />
        </button>
      </div>
      <div :class="{ 'mh-100': supportsComputedAlerts }" class="dropdown-content">
        <alert-widget-form
          ref="widgetForm"
          :disabled="formDisabled"
          :alerts-to-manage="alertsToManage"
          :relevant-queries="relevantQueries"
          @create="handleCreate"
          @update="handleUpdate"
          @delete="handleDelete"
          @cancel="handleDropdownClose"
          @setAction="handleSetApiAction"
        />
      </div>
    </div>
  </div>
</template>
