<script>
import { GlDropdown, GlDropdownItem } from '@gitlab/ui';
import { FILE_QUANTITIES } from '../constants';

export default {
  components: {
    GlDropdown,
    GlDropdownItem,
  },
  props: {
    selected: {
      type: Number,
      required: true,
    },
    fileQuantityOptions: {
      type: Array,
      required: false,
      default: () => FILE_QUANTITIES,
    },
  },
  computed: {
    selectedFileQuantityText() {
      return this.selected.toString();
    },
  },
  methods: {
    onSelect(fileQuantity) {
      this.$emit('selected', fileQuantity);
    },
  },
};
</script>
<template>
  <gl-dropdown
    toggle-class="dropdown-menu-toggle w-100"
    menu-class="w-100 mw-100"
    :text="selectedFileQuantityText"
  >
    <gl-dropdown-item
      v-for="option in fileQuantityOptions"
      :key="option"
      class="w-100"
      @click="onSelect(option)"
      >{{ option }}</gl-dropdown-item
    >
  </gl-dropdown>
</template>
