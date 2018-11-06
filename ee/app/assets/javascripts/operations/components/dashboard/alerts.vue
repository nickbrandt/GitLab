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
    lastAlert: {
      type: Object,
      required: false,
      default: null,
    },
    alertPath: {
      type: String,
      required: false,
      default: null,
    },
  },
  computed: {
    alertClasses() {
      return {
        'text-success': this.count <= 0,
        'text-warning': this.count > 0,
      };
    },
    alertCount() {
      return sprintf(__('%{count} %{alerts}'), {
        count: this.count,
        alerts: this.pluralizedAlerts,
      });
    },
    alertLinkTitle() {
      return sprintf(__('View %{alerts}'), { alerts: this.pluralizedAlerts });
    },
    lastAlertText() {
      if (this.count === 0 || this.lastAlert === null) {
        return __('None');
      }
      const ellipsis = this.count > 1 ? '\u2026' : '';

      return `${this.lastAlert.operator} ${this.lastAlert.threshold}${ellipsis}`;
    },
    pluralizedAlerts() {
      return n__('Alert', 'Alerts', this.count);
    },
  },
};
</script>

<template>
  <div class="row">
    <div
      class="col-12 d-flex align-items-center"
    >
      <icon
        :class="alertClasses"
        name="warning"
      />
      <span
        class="js-alert-count text-secondary prepend-left-4"
      >
        {{ alertCount }}
      </span>
    </div>
    <div class="js-last-alert col-12">
      <a
        v-if="alertPath"
        :href="alertPath"
        class="js-alert-link cgray"
      >
        <span
          v-if="lastAlert"
          class="str-truncated-60"
        >
          {{ lastAlert.title }}
        </span>
        <span>
          {{ lastAlertText }}
        </span>
      </a>
      <span v-else>
        {{ lastAlertText }}
      </span>
    </div>
  </div>
</template>
