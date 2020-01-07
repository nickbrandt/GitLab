<script>
import { GlEmptyState, GlButton } from '@gitlab/ui';

export default {
  name: 'GeoDesignsDisabled',
  components: {
    GlEmptyState,
    GlButton,
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
  },
};
</script>

<template>
  <gl-empty-state :title="__('Design Sync Not Enabled')" :svg-path="geoSvgPath">
    <template #description>
      <div class="text-center">
        <p>
          {{
            __(
              'If you believe this page to be an error, check out the links below for more information.',
            )
          }}
        </p>
        <div>
          <gl-button :href="geoTroubleshootingLink" new-style>{{
            __('Geo Troubleshooting')
          }}</gl-button>
          <gl-button :href="designManagementLink" new-style>{{
            __('Design Management')
          }}</gl-button>
        </div>
      </div>
    </template>
  </gl-empty-state>
</template>
