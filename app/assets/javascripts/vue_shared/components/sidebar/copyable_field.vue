<script>
import { GlLoadingIcon } from '@gitlab/ui';
import { __, sprintf } from '~/locale';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';

/**
 * Renders an inline field, whose value can be copied to the clipboard,
 * for use in the GitLab sidebar (issues, MRs, etc.).
 */
export default {
  name: 'CopyableField',
  components: {
    GlLoadingIcon,
    ClipboardButton,
  },
  props: {
    value: {
      type: String,
      required: true,
    },
    name: {
      type: String,
      required: true,
    },
    isLoading: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    clipboardProps() {
      return {
        category: 'tertiary',
        tooltipBoundary: 'viewport',
        tooltipPlacement: 'left',
        text: this.value,
        title: sprintf(__('Copy %{name}'), { name: this.name }),
      };
    },
    loadingIconLabel() {
      return sprintf(__('Loading %{name}'), { name: this.name });
    },
  },
};
</script>

<template>
  <div>
    <clipboard-button
      v-if="!isLoading"
      css-class="sidebar-collapsed-icon dont-change-state"
      v-bind="clipboardProps"
    />

    <div
      class="gl-display-flex gl-align-items-center gl-justify-content-space-between hide-collapsed"
    >
      <gl-loading-icon v-if="isLoading" inline :label="loadingIconLabel" />
      <template v-else>
        <span class="gl-overflow-hidden gl-text-overflow-ellipsis gl-white-space-nowrap">
          <slot></slot>
        </span>

        <clipboard-button size="small" v-bind="clipboardProps" />
      </template>
    </div>
  </div>
</template>
