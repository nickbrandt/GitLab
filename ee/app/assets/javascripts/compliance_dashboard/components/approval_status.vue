<script>
import { GlTooltipDirective } from '@gitlab/ui';

import { s__ } from '~/locale';
import CiIcon from '~/vue_shared/components/ci_icon.vue';

export default {
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    CiIcon,
  },
  props: {
    status: {
      type: String,
      required: true,
    },
  },
  computed: {
    tooltip() {
      return this.$options.tooltips[this.status];
    },
    iconName() {
      return `status_${this.status}`;
    },
    iconStatus() {
      const { status, iconName: icon } = this;
      let group = status;

      // Need to set this to be the group for warnings so the correct icon color fill is used
      if (group === 'warning') {
        group = 'success-with-warnings';
      }

      return {
        group,
        icon,
      };
    },
  },
  tooltips: {
    success: s__('ApprovalStatusTooltip|Adheres to separation of duties'),
    warning: s__('ApprovalStatusTooltip|At least one rule does not adhere to separation of duties'),
    failed: s__('ApprovalStatusTooltip|Fails to adhere to separation of duties'),
  },
};
</script>

<template>
  <a
    href="https://docs.gitlab.com/ee/user/compliance/compliance_dashboard/#approval-status-and-separation-of-duties"
  >
    <ci-icon v-gl-tooltip.left="tooltip" class="gl-display-flex" :status="iconStatus" />
  </a>
</template>
