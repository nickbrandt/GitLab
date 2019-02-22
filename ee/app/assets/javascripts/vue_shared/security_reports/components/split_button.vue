<script>
import { GlDropdown, GlDropdownItem } from '@gitlab/ui';

export default {
  components: {
    GlDropdown,
    GlDropdownItem,
  },
  props: {
    buttons: {
      type: Array,
      required: true,
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
    split
    no-caret
    variant="success"
    :text="selectedButton.name"
    @click="handleClick"
  >
    <gl-dropdown-item v-for="button in buttons" :key="button.action" @click="setButton(button)">
      <strong>{{ button.name }}</strong>
      <br />
      <span>{{ button.tagline }}</span>
    </gl-dropdown-item>
  </gl-dropdown>
</template>
