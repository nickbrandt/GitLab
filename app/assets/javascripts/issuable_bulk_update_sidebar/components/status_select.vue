<script>
import { GlDropdown, GlDropdownItem } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  name: 'StatusSelect',
  components: {
    GlDropdown,
    GlDropdownItem,
  },
  data() {
    return {
      status: null,
    };
  },
  computed: {
    dropdownText() {
      return this.status?.text ?? __('Select status');
    },
    selectedValue() {
      return this.status?.value;
    },
  },
  selectOptions: [
    {
      value: 'reopen',
      text: __('Open'),
    },
    {
      value: 'close',
      text: __('Closed'),
    },
  ],
};
</script>
<template>
  <div>
    <input type="hidden" name="update[state_event]" :value="selectedValue" />
    <gl-dropdown :text="dropdownText" :title="__('Change status')" class="gl-w-full">
      <gl-dropdown-item
        v-for="item in $options.selectOptions"
        :key="item.value"
        :is-checked="selectedValue === item.value"
        is-check-item
        :title="item.text"
        @click="status = item"
      >
        {{ item.text }}
      </gl-dropdown-item>
    </gl-dropdown>
  </div>
</template>
