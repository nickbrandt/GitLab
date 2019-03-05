<script>
import { mapGetters, mapActions } from 'vuex';
import { GlDropdown, GlDropdownItem } from '@gitlab/ui';
import Icon from '~/vue_shared/components/icon.vue';
import ReportTypePopover from './report_type_popover.vue';

export default {
  components: {
    GlDropdown,
    GlDropdownItem,
    ReportTypePopover,
    Icon,
  },
  props: {
    filterId: {
      type: String,
      required: true,
    },
    dashboardDocumentation: {
      type: String,
      required: true,
    },
  },
  computed: {
    ...mapGetters('filters', ['getFilter', 'getSelectedOptions', 'getSelectedOptionNames']),
    filter() {
      return this.getFilter(this.filterId);
    },
    selection() {
      return this.getFilter(this.filterId).selection;
    },
    selectedOptionText() {
      return this.getSelectedOptionNames(this.filterId) || '-';
    },
  },
  methods: {
    ...mapActions('filters', ['setFilter']),
    clickFilter(option) {
      this.setFilter({
        filterId: this.filterId,
        optionId: option.id,
      });
    },
    isSelected(option) {
      return this.selection.has(option.id);
    },
  },
};
</script>

<template>
  <div class="dashboard-filter">
    <strong class="js-name">{{ filter.name }}</strong>
    <report-type-popover
      v-if="filterId === 'report_type'"
      :dashboard-documentation="dashboardDocumentation"
    />
    <gl-dropdown class="d-block mt-1">
      <template slot="button-content">
        <span class="text-truncate">
          {{ selectedOptionText.firstOption }}
        </span>
        <span v-if="selectedOptionText.extraOptionCount" class="flex-grow-1 ml-1">
          {{ selectedOptionText.extraOptionCount }}
        </span>

        <i class="fa fa-chevron-down" aria-hidden="true"></i>
      </template>

      <gl-dropdown-item
        v-for="option in filter.options"
        :key="option.id"
        @click="clickFilter(option)"
      >
        <icon
          v-if="isSelected(option)"
          class="vertical-align-middle js-check"
          name="mobile-issue-close"
        />
        <span class="vertical-align-middle" :class="{ 'prepend-left-20': !isSelected(option) }">{{
          option.name
        }}</span>
      </gl-dropdown-item>
    </gl-dropdown>
  </div>
</template>

<style>
.dashboard-filter .dropdown-toggle {
  display: flex;
  justify-content: space-between;
  align-items: center;
  width: 100%;
}
</style>
