<script>
import { GlBadge, GlLoadingIcon, GlModalDirective } from '@gitlab/ui';
import { s__, sprintf } from '~/locale';
import createFlash from '~/flash';
import Icon from '~/vue_shared/components/icon.vue';
import AlertWidgetForm from './alert_widget_form.vue';
import AlertsService from '../services/alerts_service';
import { alertsValidator, queriesValidator } from '../validators';

export default {
  components: {
    AlertWidgetForm,
    GlBadge,
    GlLoadingIcon,
    Icon,
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
      const alertsToManage = Object.keys(this.alertsToManage);
      const alertCountMsg = sprintf(s__('PrometheusAlerts|%{count} alerts applied'), {
        count: alertsToManage.length,
      });

      return alertsToManage.length > 1
        ? alertCountMsg
        : alertsToManage.map(this.formatAlertSummary)[0];
    },
  },
  created() {
    this.service = new AlertsService({ alertsEndpoint: this.alertsEndpoint });
    this.fetchAlertData();
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
    showModal() {
      this.$root.$emit('bv::show::modal', this.modalId);
    },
    hideModal() {
      this.errorMessage = null;
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
  <div class="prometheus-alert-widget dropdown flex-grow-2 overflow-hidden">
    <span v-if="errorMessage" class="alert-error-message">{{ errorMessage }}</span>
    <span
      v-else
      class="alert-current-setting text-secondary cursor-pointer d-flex align-items-end"
      @click="showModal"
    >
      <gl-badge
        v-if="alertSummary"
        variant="secondary"
        class="d-flex-center text-secondary text-truncate"
      >
        <icon name="notifications" class="s18 append-right-4" :size="16" />
        <span class="text-truncate">{{ alertSummary }}</span>
      </gl-badge>
      <gl-loading-icon v-show="isLoading" :inline="true" />
    </span>
    <alert-widget-form
      ref="widgetForm"
      :disabled="isLoading"
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
