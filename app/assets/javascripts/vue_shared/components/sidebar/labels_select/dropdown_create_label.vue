<script>
import { __ } from '~/locale';
import { GlButton } from '@gitlab/ui';

export default {
  components: {
    GlButton,
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
    <div class="dropdown-title">
      <gl-button
        :aria-label="__('Go back')"
        class="dropdown-title-button dropdown-menu-back"
        icon="arrow-left"
      />
      {{ headerTitle }}
      <gl-button
        :aria-label="__('Close')"
        class="dropdown-title-button dropdown-menu-close"
        icon="close"
      >
        <i aria-hidden="true" class="fa fa-times dropdown-menu-close-icon" data-hidden="true"> </i>
      </gl-button>
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
          v-for="(color, index) in suggestedColors"
          :key="index"
          :data-color="color"
          :style="{
            backgroundColor: color,
          }"
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
        <gl-button
          type="button"
          class="js-new-label-btn disabled"
          category="secondary"
          variant="default"
        >
          {{ __('Create') }}
        </gl-button>
        <gl-button type="button" class="js-cancel-label-btn" category="secondary" variant="default">
          {{ __('Cancel') }}
        </gl-button>
      </div>
    </div>
  </div>
</template>
