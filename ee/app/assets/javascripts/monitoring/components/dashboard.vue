<script>
import CustomMetricsFormFields from 'ee/custom_metrics/components/custom_metrics_form_fields.vue';
import CeDashboard from '~/monitoring/components/dashboard.vue';
import AlertWidget from './alert_widget.vue';

export default {
  components: {
    AlertWidget,
    CustomMetricsFormFields,
  },
  extends: CeDashboard,
  data() {
    return {
      allAlerts: {},
    };
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
