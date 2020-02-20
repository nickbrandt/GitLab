<script>
import { SEVERITY_LEVELS } from 'ee/security_dashboard/store/constants';
import { GlIcon } from '@gitlab/ui';

const classNameMap = {
  critical: 'text-danger-800',
  high: 'text-danger-600',
  medium: 'text-warning-400',
  low: 'text-warning-300',
  info: 'text-primary-400',
  unknown: 'text-secondary-400',
};

export default {
  name: 'SeverityBadge',
  components: {
    GlIcon,
  },
  props: {
    severity: {
      type: String,
      required: true,
    },
  },
  computed: {
    className() {
      return classNameMap[this.severity.toLowerCase()];
    },
    iconName() {
      return `severity-${this.severity.toLowerCase()}`;
    },
    severityTitle() {
      return SEVERITY_LEVELS[this.severity.toLowerCase()] || this.severity;
    },
  },
};
</script>

<template>
  <div v-if="severity && severity != ' '" class="severity-badge gl-text-gray-900">
    <span :class="className"><gl-icon :name="iconName" :size="12"/></span>{{ severityTitle }}
  </div>
</template>

<style>
.severity-badge {
  text-align: left;
  white-space: nowrap;
}
.severity-badge svg {
  margin-right: 8px;
}
</style>
