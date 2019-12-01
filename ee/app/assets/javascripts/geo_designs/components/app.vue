<script>
import GeoDesignsDisabled from './geo_designs_disabled.vue';

export default {
  name: 'GeoDesignsApp',
  components: {
    GeoDesignsDisabled,
  },
  props: {
    geoSvgPath: {
      type: String,
      required: true,
    },
    geoTroubleshootingLink: {
      type: String,
      required: true,
    },
    designManagementLink: {
      type: String,
      required: true,
    },
    designsEnabled: {
      type: Boolean,
      required: true,
    },
  },
};
</script>

<template>
  <article class="geo-designs-container">
    <h2 v-if="designsEnabled">{{ __('Designs coming soon.') }}</h2>
    <geo-designs-disabled
      v-else
      :geo-svg-path="geoSvgPath"
      :geo-troubleshooting-link="geoTroubleshootingLink"
      :design-management-link="designManagementLink"
    />
  </article>
</template>
