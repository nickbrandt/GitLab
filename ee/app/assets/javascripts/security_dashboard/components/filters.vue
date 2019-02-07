<script>
import { mapState } from 'vuex';
import DashboardFilter from './filter.vue';

export default {
  components: {
    DashboardFilter,
  },
  props: {
    dashboardDocumentation: {
      type: String,
      required: true,
    },
  },
  computed: {
    ...mapState('filters', ['filters']),
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
        :dashboard-documentation="dashboardDocumentation"
      />
    </div>
  </div>
</template>
