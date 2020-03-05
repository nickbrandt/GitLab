<script>
import { GlIcon, GlLoadingIcon, GlTooltip } from '@gitlab/ui';
import { s__ } from '~/locale';
import { healthStatusColorMap, healthStatusTextMap } from '../../constants';

export default {
  components: {
    GlIcon,
    GlLoadingIcon,
    GlTooltip,
  },
  props: {
    isFetching: {
      type: Boolean,
      required: false,
      default: false,
    },
    status: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    statusText() {
      return this.status ? healthStatusTextMap[this.status] : s__('Sidebar|None');
    },
    statusColor() {
      return healthStatusColorMap[this.status];
    },
    tooltipText() {
      let tooltipText = s__('Sidebar|Status');

      if (this.status) {
        tooltipText += `: ${this.statusText}`;
      }

      return tooltipText;
    },
  },
};
</script>

<template>
  <div class="block">
    <div ref="status" class="sidebar-collapsed-icon">
      <gl-icon name="status" :size="14" />

      <gl-loading-icon v-if="isFetching" />
      <p v-else class="collapse-truncated-title px-1">{{ statusText }}</p>
    </div>
    <gl-tooltip :target="() => $refs.status" boundary="viewport" placement="left">
      {{ tooltipText }}
    </gl-tooltip>

    <div class="hide-collapsed">
      <p class="title">{{ s__('Sidebar|Status') }}</p>

      <gl-loading-icon v-if="isFetching" :inline="true" />
      <p v-else class="value m-0" :class="{ 'no-value': !status }">
        <gl-icon
          v-if="status"
          name="severity-low"
          :size="14"
          class="align-bottom mr-2"
          :class="statusColor"
        />
        {{ statusText }}
      </p>
    </div>
  </div>
</template>
