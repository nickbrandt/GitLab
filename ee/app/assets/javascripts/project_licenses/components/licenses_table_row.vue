<script>
import { GlLink, GlSkeletonLoading } from '@gitlab/ui';
import LicenseComponentLinks from './license_component_links.vue';

export default {
  name: 'LicensesTableRow',
  components: {
    LicenseComponentLinks,
    GlLink,
    GlSkeletonLoading,
  },
  props: {
    license: {
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
  <div class="gl-responsive-table-row flex-md-column align-items-md-stretch px-2">
    <gl-skeleton-loading
      v-if="isLoading"
      :lines="1"
      class="d-flex flex-column justify-content-center h-auto"
    />

    <div v-else class="d-md-flex align-items-baseline js-license-row">
      <!-- Name-->
      <div class="table-section section-30 section-wrap pr-md-3">
        <div class="table-mobile-header" role="rowheader">
          {{ s__('Licenses|Name') }}
        </div>
        <div class="table-mobile-content">
          <gl-link v-if="license.url" :href="license.url" target="_blank">{{
            license.name
          }}</gl-link>
          <template v-else>{{ license.name }}</template>
        </div>
      </div>

      <!-- Component -->
      <div class="table-section section-70 section-wrap pr-md-3">
        <div class="table-mobile-header" role="rowheader">{{ s__('Licenses|Component') }}</div>
        <div class="table-mobile-content">
          <license-component-links :components="license.components" :title="license.name" />
        </div>
      </div>
    </div>
  </div>
</template>
