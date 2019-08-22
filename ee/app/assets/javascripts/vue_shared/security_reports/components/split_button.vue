<script>
import { GlDropdown, GlDropdownItem } from '@gitlab/ui';
import Icon from '~/vue_shared/components/icon.vue';

export default {
  components: {
    GlDropdown,
    GlDropdownItem,
    Icon,
  },
  props: {
    buttons: {
      type: Array,
      required: true,
    },
    disabled: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data: () => ({
    selectedButton: {},
  }),
  created() {
    this.setButton(this.buttons[0]);
  },
  methods: {
    setButton(button) {
      this.selectedButton = button;
    },
    handleClick() {
      this.$emit(this.selectedButton.action);
    },
  },
};
</script>

<template>
  <gl-dropdown
    v-if="selectedButton"
    :disabled="disabled"
    no-caret
    right
    split
    variant="success"
    :text="selectedButton.name"
    @click="handleClick"
  >
    <gl-dropdown-item v-for="button in buttons" :key="button.action" @click="setButton(button)">
      <div class="media">
        <div>
          <icon v-if="selectedButton === button" class="append-right-5" name="mobile-issue-close" />
        </div>
        <div class="media-body" :class="{ 'prepend-left-20': selectedButton !== button }">
          <strong>{{ button.name }}</strong>
          <br />
          <span>{{ button.tagline }}</span>
        </div>
      </div>
    </gl-dropdown-item>
  </gl-dropdown>
</template>
