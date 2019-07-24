<script>
import { mapActions, mapState } from 'vuex';
import { GlButton, GlDropdown, GlDropdownItem, GlTooltipDirective } from '@gitlab/ui';
import Icon from '~/vue_shared/components/icon.vue';
import { DEPENDENCY_LIST_TYPES } from '../store/constants';
import {
  SORT_FIELDS,
  SORT_FIELDS_WITH_SEVERITY,
  SORT_ORDER,
} from '../store/modules/list/constants';

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
  inject: {
    dependencyListVulnerabilities: {
      from: 'dependencyListVulnerabilities',
      default: false,
    },
  },
  props: {
    namespace: {
      type: String,
      required: true,
      validator: value => Object.values(DEPENDENCY_LIST_TYPES).includes(value),
    },
  },
  data() {
    return {
      sortFields: this.dependencyListVulnerabilities ? SORT_FIELDS_WITH_SEVERITY : SORT_FIELDS,
    };
  },
  computed: {
    ...mapState({
      sortField(state) {
        return state[this.namespace].sortField;
      },
      sortOrder(state) {
        return state[this.namespace].sortOrder;
      },
      downloadEndpoint(state, getters) {
        return getters[`${this.namespace}/downloadEndpoint`];
      },
    }),
    sortFieldName() {
      return this.sortFields[this.sortField];
    },
    sortOrderIcon() {
      return this.sortOrder === SORT_ORDER.ascending ? 'sort-lowest' : 'sort-highest';
    },
  },
  methods: {
    ...mapActions({
      setSortField(dispatch, field) {
        dispatch(`${this.namespace}/setSortField`, field);
      },
      toggleSortOrder(dispatch) {
        dispatch(`${this.namespace}/toggleSortOrder`);
      },
    }),
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
              class="flex-shrink-0 append-right-4"
              :class="{ invisible: !isCurrentSortField(id) }"
              name="mobile-issue-close"
            />
            {{ name }}
          </span>
        </gl-dropdown-item>
      </gl-dropdown>
      <gl-button
        v-gl-tooltip
        :title="__('Sort direction')"
        class="flex-grow-0 js-sort-order"
        @click="toggleSortOrder"
      >
        <icon :name="sortOrderIcon" />
      </gl-button>
    </div>
    <gl-button
      v-gl-tooltip
      :href="downloadEndpoint"
      download="dependencies.json"
      :title="s__('Dependencies|Export as JSON')"
      class="js-download"
    >
      <icon name="download" />
    </gl-button>
  </div>
</template>
