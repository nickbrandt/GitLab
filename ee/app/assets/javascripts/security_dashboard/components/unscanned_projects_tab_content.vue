<script>
import { GlLoadingIcon } from '@gitlab/ui';

export default {
  components: {
    GlLoadingIcon,
  },
  props: {
    isLoading: {
      type: Boolean,
      required: false,
      default: false,
    },
    isEmpty: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  css: {
    style: {
      maxHeight: '245px',
      overflowY: 'auto',
      // gl-tabs have a font-size and line-height of 1 - this causes the scrollbar to appear
      // setting the line-height to 'normal' prevents this
      lineHeight: 'normal',
    },
  },
};
</script>

<template>
  <div class="mx-3 my-2" :style="$options.css.style">
    <gl-loading-icon v-if="isLoading" size="sm" />
    <template v-else>
      <template v-if="!isEmpty">
        <slot></slot>
      </template>
      <p v-else class="mb-0">
        {{ s__('UnscannedProjects|Your projects are up do date! Nice job!') }}
      </p>
    </template>
  </div>
</template>
