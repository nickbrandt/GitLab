<script>
import { GlSkeletonLoading } from '@gitlab/ui';

export default {
  name: 'DependenciesTableRow',
  components: {
    GlSkeletonLoading,
  },
  props: {
    dependency: {
      type: Object,
      required: false,
      default: null,
    },
    isLoading: {
      type: Boolean,
      required: false,
      default: true,
    },
  },
};
</script>

<template>
  <div class="gl-responsive-table-row p-2">
    <gl-skeleton-loading
      v-if="isLoading"
      :lines="1"
      class="d-flex flex-column justify-content-center"
    />
    <template v-else>
      <div class="table-section section-20 section-wrap">
        <div class="table-mobile-header" role="rowheader">{{ s__('Dependencies|Component') }}</div>
        <div class="table-mobile-content">{{ dependency.name }}</div>
      </div>

      <div class="table-section section-15">
        <div class="table-mobile-header" role="rowheader">{{ s__('Dependencies|Version') }}</div>
        <div class="table-mobile-content">{{ dependency.version }}</div>
      </div>

      <div class="table-section section-20 section-wrap">
        <div class="table-mobile-header" role="rowheader">{{ s__('Dependencies|Packager') }}</div>
        <div class="table-mobile-content">{{ dependency.packager }}</div>
      </div>

      <div class="table-section flex-grow-1 section-wrap">
        <div class="table-mobile-header" role="rowheader">{{ s__('Dependencies|Location') }}</div>
        <div class="table-mobile-content">
          <a :href="dependency.location.blob_path">{{ dependency.location.path }}</a>
        </div>
      </div>
    </template>
  </div>
</template>
