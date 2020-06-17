<script>
import { __ } from '~/locale';
import { mapState } from 'vuex';
import { GlNewDropdown, GlNewDropdownItem } from '@gitlab/ui';

const options = [
  {
    value: 'instance',
    text: __('Use instance level settings'),
  },
  {
    value: 'project',
    text: __('Use custom settings'),
  },
];

const defaultOption = options[0];
const customOption = options[1];

export default {
  name: 'OverrideDropdown',
  components: {
    GlNewDropdown,
    GlNewDropdownItem,
  },
  props: {},
  data() {
    return {
      options,
      selected: defaultOption,
    };
  },
  computed: {
    ...mapState(['override']),
  },
  methods: {
    onClick(option) {
      this.selected = option;
      this.$store.dispatch('setOverride', option === customOption);
    },
  },
};
</script>

<template>
  <div
    class="gl-display-flex gl-justify-content-space-between gl-align-items-baseline gl-py-4 gl-mt-5 gl-mb-6 gl-border-t-1 gl-border-t-solid gl-border-b-1 gl-border-b-solid gl-border-gray-100"
  >
    <span>{{ __('This integration has multiple settings available.') }}</span>
    <gl-new-dropdown :text="selected.text">
      <gl-new-dropdown-item v-for="option in options" :key="option.value" @click="onClick(option)">
        {{ option.text }}
      </gl-new-dropdown-item>
    </gl-new-dropdown>
  </div>
</template>
