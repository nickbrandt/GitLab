<script>
import { mapGetters } from 'vuex';
import DashboardFilter from './filter.vue';
import GlToggleVuex from '~/vue_shared/components/gl_toggle_vuex.vue';

export default {
  components: {
    DashboardFilter,
    GlToggleVuex,
  },
  computed: {
    ...mapGetters({
      filters: 'filters/visibleFilters',
    }),
  },
};
</script>

<template>
  <div class="dashboard-filters border-bottom bg-light">
    <div class="row mx-0 p-2">
      <dashboard-filter
        v-for="filter in filters"
        :key="filter.id"
        class="col-sm-6 col-md-4 col-lg-2 p-2 js-filter"
        :filter-id="filter.id"
      />
      <div class="ml-lg-auto p-2">
        <strong>{{ s__('SecurityDashboard|Hide dismissed') }}</strong>
        <gl-toggle-vuex
          class="d-block mt-1 js-toggle"
          store-module="filters"
          state-property="hideDismissed"
          set-action="setToggleValue"
        />
      </div>
    </div>
  </div>
</template>
