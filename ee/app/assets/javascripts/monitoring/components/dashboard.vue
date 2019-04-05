<script>
import CeDashboard from '~/monitoring/components/dashboard.vue';
import AlertWidget from './alert_widget.vue';

export default {
  components: {
    AlertWidget,
  },
  extends: CeDashboard,
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
  },
  data() {
    return {
      allAlerts: {},
    };
  },
  computed: {
    alertsAvailable() {
      return this.prometheusAlertsAvailable && this.alertsEndpoint;
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
