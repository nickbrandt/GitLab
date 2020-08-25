<script>
import { GlIcon } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  components: {
    GlIcon,
  },
  props: {
    headerTitle: {
      type: String,
      required: false,
      default: () => __('Create new label'),
    },
  },
  created() {
    this.suggestedColors = gon.suggested_label_colors;
  },
};
</script>

<template>
  <div class="dropdown-page-two dropdown-new-label">
    <div class="dropdown-title gl-display-flex gl-justify-content-space-between">
      <button
        :aria-label="__('Go back')"
        type="button"
        class="dropdown-title-button dropdown-menu-back"
      >
        <i aria-hidden="true" class="fa fa-arrow-left" data-hidden="true"> </i>
      </button>
      {{ headerTitle }}
      <button
        :aria-label="__('Close')"
        type="button"
        class="dropdown-title-button dropdown-menu-close"
      >
        <gl-icon name="close" aria-hidden="true" class="dropdown-menu-close-icon" />
      </button>
    </div>
    <div class="dropdown-content">
      <div class="dropdown-labels-error js-label-error"></div>
      <input
        id="new_label_name"
        :placeholder="__('Name new label')"
        type="text"
        class="default-dropdown-input"
      />
      <div class="suggest-colors suggest-colors-dropdown">
        <a
          v-for="(color, hex) in suggestedColors"
          :key="hex"
          :data-color="color"
          :style="{ backgroundColor: hex }"
          href="#"
        >
          &nbsp;
        </a>
      </div>
      <div class="dropdown-label-color-input">
        <div class="dropdown-label-color-preview js-dropdown-label-color-preview"></div>
        <input
          id="new_label_color"
          :placeholder="__('Assign custom color like #FF0000')"
          type="text"
          class="default-dropdown-input"
        />
      </div>
      <div class="clearfix">
        <button type="button" class="btn btn-primary float-left js-new-label-btn disabled">
          {{ __('Create') }}
        </button>
        <button type="button" class="btn btn-default float-right js-cancel-label-btn">
          {{ __('Cancel') }}
        </button>
      </div>
    </div>
  </div>
</template>
