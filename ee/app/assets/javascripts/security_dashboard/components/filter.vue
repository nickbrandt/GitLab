<script>
import { GlDropdown, GlDropdownItem, GlSearchBoxByType } from '@gitlab/ui';

export default {
  components: {
    GlDropdown,
    GlDropdownItem,
    GlSearchBoxByType,
  },
  props: {
    filter: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      filterTerm: '',
    };
  },
  computed: {
    filterId() {
      return this.filter.id;
    },
    selection() {
      return this.filter.selection;
    },
    firstSelectedOption() {
      return this.filter.options.find(option => this.selection.has(option.id))?.name || '-';
    },
    extraOptionCount() {
      return this.selection.size - 1;
    },
    filteredOptions() {
      return this.filter.options.filter(option =>
        option.name.toLowerCase().includes(this.filterTerm.toLowerCase()),
      );
    },
    qaSelector() {
      return `filter_${this.filter.name.toLowerCase().replace(' ', '_')}_dropdown`;
    },
  },
  methods: {
    clickFilter(option) {
      this.$emit('setFilter', { filterId: this.filterId, optionId: option.id });
    },
    isSelected(option) {
      return this.selection.has(option.id);
    },
    closeDropdown() {
      this.$refs.dropdown.$children[0].hide(true);
    },
  },
};
</script>

<template>
  <div class="dashboard-filter">
    <strong class="js-name">{{ filter.name }}</strong>
    <gl-dropdown
      ref="dropdown"
      class="gl-display-block gl-mt-2"
      menu-class="dropdown-extended-height"
      :header-text="filter.name"
      toggle-class="gl-display-flex gl-w-full gl-justify-content-space-between! gl-align-items-center"
    >
      <template slot="button-content">
        <span class="text-truncate" :data-qa-selector="qaSelector">
          {{ firstSelectedOption }}
        </span>
        <span v-if="extraOptionCount" class="flex-grow-1 ml-1">
          {{ n__('+%d more', '+%d more', extraOptionCount) }}
        </span>
        <i class="fa fa-chevron-down" aria-hidden="true"></i>
      </template>

      <gl-search-box-by-type
        v-if="filter.options.length >= 20"
        ref="searchBox"
        v-model="filterTerm"
        :placeholder="__('Filter...')"
      />

      <gl-dropdown-item
        v-for="option in filteredOptions"
        :key="option.id"
        data-qa-selector="filter_dropdown_content"
        :is-check-item="true"
        :is-checked="isSelected(option)"
        @click="clickFilter(option)"
      >
        {{ option.name }}
      </gl-dropdown-item>

      <gl-dropdown-item v-if="filteredOptions.length === 0" class="gl-pointer-events-none">
        {{ __('No matching results') }}
      </gl-dropdown-item>
    </gl-dropdown>
  </div>
</template>
