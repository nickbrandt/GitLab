<script>
import { GlDropdownDivider } from '@gitlab/ui';
import { pull } from 'lodash';
import { activityOptions } from '../../helpers';
import FilterBody from './filter_body.vue';
import FilterItem from './filter_item.vue';
import StandardFilter from './standard_filter.vue';

const { WITH_ISSUES, NO_LONGER_DETECTED } = activityOptions;

export default {
  components: { FilterBody, FilterItem, GlDropdownDivider },
  extends: StandardFilter,
  computed: {
    allOptionId() {
      return this.filter.allOption.id;
    },
    options() {
      const { allOption, noActivityOption, multiselectOptions } = this.filter;
      return [allOption, noActivityOption, ...multiselectOptions];
    },
    isAllOptionSelected() {
      return this.selectedSet.has(this.allOptionId);
    },
    // This is used as variables for the vulnerability list Apollo query.
    filterObject() {
      return {
        hasIssues: this.isAllOptionSelected ? undefined : this.isSelected(WITH_ISSUES),
        hasResolution: this.isAllOptionSelected ? undefined : this.isSelected(NO_LONGER_DETECTED),
      };
    },
  },
  methods: {
    selectAllOption() {
      this.selectedIds = [this.allOptionId];
    },
    toggleNoActivityOption() {
      const optionId = this.filter.noActivityOption.id;
      this.selectedIds = this.selectedSet.has(optionId) ? [this.allOptionId] : [optionId];
    },
    toggleMultiselectOption(option) {
      pull(this.selectedIds, this.filter.noActivityOption.id);
      this.toggleOption(option);
    },
  },
};
</script>

<template>
  <filter-body :name="filter.name" :selected-options="selectedOptions">
    <filter-item
      :is-checked="isAllOptionSelected"
      :text="filter.allOption.name"
      :data-testid="`${filter.id}:${filter.allId}`"
      @click="selectAllOption"
    />
    <filter-item
      :is-checked="isSelected(filter.noActivityOption)"
      :text="filter.noActivityOption.name"
      data-testid="`${filter.id}:${filter.noActivityOption.name}`"
      @click="toggleNoActivityOption"
    />
    <gl-dropdown-divider />
    <filter-item
      v-for="option in filter.multiselectOptions"
      :key="option.name"
      :is-checked="isSelected(option)"
      :text="option.name"
      :data-testid="`option:${option.name}`"
      @click="toggleMultiselectOption(option)"
    />
  </filter-body>
</template>
