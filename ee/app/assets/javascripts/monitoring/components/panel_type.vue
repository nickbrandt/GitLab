<script>
import CustomMetricsFormFields from 'ee/custom_metrics/components/custom_metrics_form_fields.vue';
import CePanelType from '~/monitoring/components/panel_type.vue';
import AlertWidget from './alert_widget.vue';

export default {
  components: {
    AlertWidget,
    CustomMetricsFormFields,
  },
  extends: CePanelType,
  props: {
    alertsEndpoint: {
      type: String,
      required: false,
      default: null,
    },
    prometheusAlertsAvailable: {
      type: Boolean,
      required: false,
      default: false,
    },
    groupId: {
      type: String,
      required: false,
      default: 'panel-type-chart',
    },
  },
  data() {
    return {
      allAlerts: {},
    };
  },
  computed: {
    alertWidgetAvailable() {
      if (!this.prometheusAlertsAvailable) {
        return false;
      }
      // true if any metric has an `alert_path` defined
      if (!this.graphData || !this.graphData.metrics) {
        return false;
      }
      // TODO Repplace this for ID
      return this.graphData.metrics.reduce((acc, metric) => {
        return acc || Boolean(metric.alert_path);
      }, false);
    },
  },
  methods: {
    setAlerts(alertPath, alertAttributes) {
      if (alertAttributes) {
        this.$set(this.allAlerts, alertPath, alertAttributes);
      } else {
        this.$delete(this.allAlerts, alertPath);
      }
    },
  },
};
</script>
