<script>
import { mapActions, mapState } from 'vuex';
import { GlButton, GlDropdown, GlDropdownItem, GlTooltipDirective } from '@gitlab/ui';
import Icon from '~/vue_shared/components/icon.vue';
import { SORT_ORDER } from '../store/constants';

export default {
  name: 'DependenciesActions',
  components: {
    GlButton,
    GlDropdown,
    GlDropdownItem,
    Icon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  computed: {
    ...mapState(['dependenciesDownloadEndpoint', 'sortField', 'sortFields', 'sortOrder']),
    sortFieldName() {
      return this.sortFields[this.sortField];
    },
    sortOrderIcon() {
      return this.sortOrder === SORT_ORDER.ascending ? 'sort-lowest' : 'sort-highest';
    },
  },
  methods: {
    ...mapActions(['setSortField', 'toggleSortOrder']),
    isCurrentSortField(id) {
      return id === this.sortField;
    },
  },
};
</script>

<template>
  <div class="btn-toolbar">
    <div class="btn-group flex-grow-1 mr-2">
      <gl-dropdown :text="sortFieldName" class="flex-grow-1 text-center" right>
        <gl-dropdown-item v-for="(name, id) in sortFields" :key="id" @click="setSortField(id)">
          <span class="d-flex">
            <icon
              v-if="isCurrentSortField(id)"
              class="flex-shrink-0 js-check"
              name="mobile-issue-close"
            />
            <span :class="isCurrentSortField(id) ? 'prepend-left-4' : 'prepend-left-20'">{{
              name
            }}</span>
          </span>
        </gl-dropdown-item>
      </gl-dropdown>
      <gl-button
        v-gl-tooltip
        :title="__('Sort direction')"
        class="flex-grow-0"
        @click="toggleSortOrder"
      >
        <icon :name="sortOrderIcon" />
      </gl-button>
    </div>
    <gl-button
      v-gl-tooltip
      :href="dependenciesDownloadEndpoint"
      download="dependencies.json"
      :title="s__('Dependencies|Export as JSON')"
    >
      <icon name="download" />
    </gl-button>
  </div>
</template>
