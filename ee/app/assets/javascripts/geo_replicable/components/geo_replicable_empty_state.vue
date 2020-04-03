<script>
import { mapState } from 'vuex';
import { GlEmptyState } from '@gitlab/ui';
import { s__, sprintf } from '~/locale';

export default {
  name: 'GeoReplicableEmptyState',
  components: {
    GlEmptyState,
  },
  props: {
    issuesSvgPath: {
      type: String,
      required: true,
    },
    geoTroubleshootingLink: {
      type: String,
      required: true,
    },
  },
  computed: {
    ...mapState(['replicableType']),
    linkText() {
      return sprintf(
        s__(
          'If you believe this may be an error, please refer to the %{linkStart}Geo Troubleshooting%{linkEnd} documentation for more information.',
        ),
        {
          linkStart: `<a href="${this.geoTroubleshootingLink}" target="_blank">`,
          linkEnd: '</a>',
        },
        false,
      );
    },
  },
};
</script>

<template>
  <gl-empty-state
    :title="sprintf(__('No %{replicableType} match this filter'), { replicableType })"
    :svg-path="issuesSvgPath"
  >
    <template #description>
      <div class="text-center">
        <p>{{ __('Adjust your filters/search criteria above.') }}</p>
        <p v-html="linkText"></p>
      </div>
    </template>
  </gl-empty-state>
</template>
