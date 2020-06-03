<script>
import { mapState, mapActions } from 'vuex';
import { GlNewDropdown as GlDropdown, GlNewDropdownItem as GlDropdownItem } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  components: {
    GlDropdown,
    GlDropdownItem,
  },
  computed: {
    ...mapState(['isShowingEpicsSwimlanes']),

    groupByEpicLabel() {
      return __('Epic');
    },
    groupByNoneLabel() {
      return __('No grouping');
    },
    dropdownLabel() {
      return this.isShowingEpicsSwimlanes ? this.groupByEpicLabel : __('None');
    },
  },
  methods: {
    ...mapActions(['toggleEpicSwimlanes']),

    onToggle() {
      this.toggleEpicSwimlanes();
    },
  },
};
</script>

<template>
  <div
    class="board-swimlanes-toggle-wrapper gl-display-flex gl-align-items-center prepend-left-10"
    data-testid="toggle-swimlanes"
  >
    <span
      class="board-swimlanes-toggle-text gl-white-space-nowrap"
      data-testid="toggle-swimlanes-label"
    >
      {{ __('Group by:') }}
    </span>
    <gl-dropdown
      right
      :text="dropdownLabel"
      toggle-class="gl-ml-2 gl-border-none gl-inset-border-1-gray-400! border-radius-default"
    >
      <gl-dropdown-item
        :is-check-item="true"
        :is-checked="!isShowingEpicsSwimlanes"
        @click="toggleEpicSwimlanes()"
        >{{ groupByNoneLabel }}</gl-dropdown-item
      >
      <gl-dropdown-item
        :is-check-item="true"
        :is-checked="isShowingEpicsSwimlanes"
        @click="toggleEpicSwimlanes()"
        >{{ groupByEpicLabel }}</gl-dropdown-item
      >
    </gl-dropdown>
  </div>
</template>
