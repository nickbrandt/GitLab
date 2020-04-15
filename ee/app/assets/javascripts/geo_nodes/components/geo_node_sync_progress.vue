<script>
import { GlPopover, GlSprintf, GlLink } from '@gitlab/ui';
import StackedProgressBar from '~/vue_shared/components/stacked_progress_bar.vue';
import Icon from '~/vue_shared/components/icon.vue';
import tooltip from '~/vue_shared/directives/tooltip';

export default {
  name: 'GeoNodeSyncProgress',
  directives: {
    tooltip,
  },
  components: {
    GlPopover,
    GlSprintf,
    GlLink,
    StackedProgressBar,
    Icon,
  },
  props: {
    itemTitle: {
      type: String,
      required: true,
    },
    itemValue: {
      type: Object,
      required: true,
      validator: value =>
        ['totalCount', 'successCount', 'failureCount'].every(key => typeof value[key] === 'number'),
    },
    itemValueStale: {
      type: Boolean,
      required: false,
      default: false,
    },
    itemValueStaleTooltip: {
      type: String,
      required: false,
      default: '',
    },
    detailsPath: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    queuedCount() {
      return this.itemValue.totalCount - this.itemValue.successCount - this.itemValue.failureCount;
    },
  },
};
</script>

<template>
  <div>
    <stacked-progress-bar
      :id="`syncProgress-${itemTitle}`"
      tabindex="0"
      :css-class="itemValueStale ? 'flex-fill' : ''"
      :hide-tooltips="true"
      :unavailable-label="__('Nothing to synchronize')"
      :success-count="itemValue.successCount"
      :failure-count="itemValue.failureCount"
      :total-count="itemValue.totalCount"
    />
    <gl-popover
      :target="`syncProgress-${itemTitle}`"
      placement="right"
      triggers="hover focus"
      :css-classes="['w-100']"
    >
      <template #title>
        <gl-sprintf :message="__('Number of %{itemTitle}')">
          <template #itemTitle>
            {{ itemTitle }}
          </template>
        </gl-sprintf>
      </template>
      <section>
        <div class="d-flex align-items-center my-1">
          <div class="mr-2 bg-transparent gl-shim-w-5 gl-shim-h-2"></div>
          <span class="flex-grow-1 mr-3">{{ __('Total') }}</span>
          <span class="font-weight-bold">{{ itemValue.totalCount.toLocaleString() }}</span>
        </div>
        <div class="d-flex align-items-center my-2">
          <div class="mr-2 bg-success-500 gl-shim-w-5 gl-shim-h-2"></div>
          <span class="flex-grow-1 mr-3">{{ __('Synced') }}</span>
          <span class="font-weight-bold">{{ itemValue.successCount.toLocaleString() }}</span>
        </div>
        <div class="d-flex align-items-center my-2">
          <div class="mr-2 bg-secondary-200 gl-shim-w-5 gl-shim-h-2"></div>
          <span class="flex-grow-1 mr-3">{{ __('Queued') }}</span>
          <span class="font-weight-bold">{{ queuedCount.toLocaleString() }}</span>
        </div>
        <div class="d-flex align-items-center my-2">
          <div class="mr-2 bg-danger-500 gl-shim-w-5 gl-shim-h-2"></div>
          <span class="flex-grow-1 mr-3">{{ __('Failed') }}</span>
          <span class="font-weight-bold">{{ itemValue.failureCount.toLocaleString() }}</span>
        </div>
        <div v-if="detailsPath" class="mt-3">
          <gl-link class="gl-font-size-small" :href="detailsPath" target="_blank">{{
            __('More information')
          }}</gl-link>
        </div>
      </section>
    </gl-popover>
    <icon
      v-if="itemValueStale"
      v-tooltip
      :title="itemValueStaleTooltip"
      :aria-label="itemValueStaleTooltip"
      name="time-out"
      class="ml-2 text-warning-500"
      data-container="body"
    />
  </div>
</template>
