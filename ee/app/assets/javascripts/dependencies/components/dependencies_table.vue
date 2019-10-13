<script>
import { s__ } from '~/locale';
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
  data() {
    const tableSections = [
      { className: 'section-20', label: s__('Dependencies|Status') },
      { className: 'section-20', label: s__('Dependencies|Component') },
      { className: 'section-10', label: s__('Dependencies|Version') },
      { className: 'section-20', label: s__('Dependencies|Packager') },
      { className: 'section-15', label: s__('Dependencies|Location') },
      { className: 'section-15', label: s__('Dependencies|License') },
    ];

    return { tableSections };
  },
};
</script>

<template>
  <div>
    <div class="gl-responsive-table-row table-row-header text-2 bg-secondary-50 px-2" role="row">
      <div
        v-for="(section, index) in tableSections"
        :key="index"
        class="table-section"
        :class="section.className"
        role="rowheader"
      >
        {{ section.label }}
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
