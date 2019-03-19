<script>
import { __, n__, sprintf } from '~/locale';
import Icon from '~/vue_shared/components/icon.vue';

export default {
  components: {
    Icon,
  },
  props: {
    count: {
      type: Number,
      required: false,
      default: 0,
    },
  },
  computed: {
    alertClasses() {
      return {
        'text-tertiary': this.count <= 0,
        'text-warning': this.count > 0,
      };
    },
    alertCount() {
      return sprintf(__('%{count} %{alerts}'), {
        count: this.count,
        alerts: this.pluralizedAlerts,
      });
    },
    pluralizedAlerts() {
      return n__('Alert', 'Alerts', this.count);
    },
  },
};
</script>

<template>
  <div class="dashboard-card-alert row">
    <div class="col-12">
      <icon
        :class="alertClasses"
        class="align-text-bottom js-dashboard-alerts-icon"
        name="warning"
      />
      <span class="js-alert-count text-secondary prepend-left-4"> {{ alertCount }} </span>
    </div>
  </div>
</template>
