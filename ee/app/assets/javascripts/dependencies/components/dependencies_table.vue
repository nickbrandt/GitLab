<script>
import DependenciesTableRow from './dependencies_table_row.vue';

export default {
  name: 'DependenciesTable',
  components: {
    DependenciesTableRow,
  },
  props: {
    dependencies: {
      type: Array,
      required: true,
    },
    isLoading: {
      type: Boolean,
      required: true,
    },
  },
};
</script>

<template>
  <div>
    <div class="gl-responsive-table-row table-row-header text-2 bg-secondary-50 px-2" role="row">
      <div class="table-section section-20" role="rowheader">
        {{ s__('Dependencies|Component') }}
      </div>
      <div class="table-section section-15" role="rowheader">
        {{ s__('Dependencies|Version') }}
      </div>
      <div class="table-section section-20" role="rowheader">
        {{ s__('Dependencies|Packager') }}
      </div>
      <div class="table-section flex-grow-1" role="rowheader">
        {{ s__('Dependencies|Location') }}
      </div>
    </div>

    <dependencies-table-row
      v-for="(dependency, index) in dependencies"
      :key="index"
      :dependency="dependency"
      :is-loading="isLoading"
    />
  </div>
</template>
