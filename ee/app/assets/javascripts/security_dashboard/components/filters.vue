<script>
import { mapState } from 'vuex';
import GlFilter from './filter.vue';

export default {
  components: {
    GlFilter,
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
      <gl-filter
        v-for="filter in filters"
        :key="filter.id"
        class="col-sm p-2 js-filter"
        :filter-id="filter.id"
        :dashboard-documentation="dashboardDocumentation"
        @change="$emit('change');"
      />
      <div class="col-sm p-2 d-md-block d-none"></div>
      <div class="col-sm p-2 d-md-block d-none"></div>
      <div class="col-sm p-2 d-md-block d-none"></div>
    </div>
  </div>
</template>
