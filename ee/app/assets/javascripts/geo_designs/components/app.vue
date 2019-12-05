<script>
import { mapActions, mapState } from 'vuex';
import { GlLoadingIcon } from '@gitlab/ui';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import GeoDesigns from './geo_designs.vue';
import GeoDesignsEmptyState from './geo_designs_empty_state.vue';
import GeoDesignsDisabled from './geo_designs_disabled.vue';

export default {
  name: 'GeoDesignsApp',
  components: {
    GlLoadingIcon,
    GeoDesigns,
    GeoDesignsEmptyState,
    GeoDesignsDisabled,
  },
  mixins: [glFeatureFlagsMixin()],
  props: {
    geoSvgPath: {
      type: String,
      required: true,
    },
    issuesSvgPath: {
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
  },
  data() {
    return {
      designsEnabled: Boolean(this.glFeatures.enableGeoDesignSync),
    };
  },
  computed: {
    ...mapState(['isLoading', 'totalDesigns']),
    hasDesigns() {
      return this.totalDesigns > 0;
    },
  },
  created() {
    this.fetchDesigns();
  },
  methods: {
    ...mapActions(['fetchDesigns']),
  },
};
</script>

<template>
  <article class="geo-designs-container">
    <section v-if="designsEnabled">
      <gl-loading-icon v-if="isLoading" size="xl" />
      <template v-else>
        <geo-designs v-if="hasDesigns" />
        <geo-designs-empty-state
          v-else
          :issues-svg-path="issuesSvgPath"
          :geo-troubleshooting-link="geoTroubleshootingLink"
        />
      </template>
    </section>
    <geo-designs-disabled
      v-else
      :geo-svg-path="geoSvgPath"
      :geo-troubleshooting-link="geoTroubleshootingLink"
      :design-management-link="designManagementLink"
    />
  </article>
</template>
