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
    ...mapGetters('filters', ['getFilter', 'getSelectedOptions']),
    filter() {
      return this.getFilter(this.filterId);
    },
    selectedOptionText() {
      const [selectedOption] = this.getSelectedOptions(this.filterId);
      return (selectedOption && selectedOption.name) || '-';
    },
  },
  methods: {
    ...mapActions('filters', ['setFilter']),
    clickFilter(option) {
      this.setFilter({
        filterId: this.filterId,
        optionId: option.id,
      });
      this.$emit('change');
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
    <gl-dropdown :text="selectedOptionText" class="d-block mt-1">
      <gl-dropdown-item
        v-for="option in filter.options"
        :key="option.id"
        @click="clickFilter(option);"
      >
        <icon
          v-if="option.selected"
          class="vertical-align-middle js-check"
          name="mobile-issue-close"
        />
        <span class="vertical-align-middle" :class="{ 'prepend-left-20': !option.selected }">{{
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
