<script>
import CsvExportButton from './csv_export_button.vue';
import Filters from './first_class_vulnerability_filters.vue';
import VulnerabilitiesCountList from './vulnerability_count_list.vue';

export default {
  components: { CsvExportButton, VulnerabilitiesCountList, Filters },
  props: {
    fullPath: {
      type: String,
      required: false,
      default: '',
    },
    projects: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  data: () => ({
    filters: {},
  }),
  methods: {
    handleFilterChange(filters) {
      this.filters = filters;
      this.$emit('filter-change', filters);
    },
  },
};
</script>

<template>
  <section class="gl-mt-4">
    <slot name="banner"></slot>

    <h2 class="gl-my-6 gl-display-flex gl-align-items-center">
      {{ s__('SecurityReports|Vulnerability Report') }}
      <csv-export-button class="gl-ml-auto" />
    </h2>

    <slot name="pipeline"></slot>

    <vulnerabilities-count-list :filters="filters" />

    <filters
      class="position-sticky gl-z-index-3 security-dashboard-filters"
      :projects="projects"
      @filter-change="handleFilterChange"
    />

    <slot></slot>
  </section>
</template>
