<script>
import { GlEmptyState } from '@gitlab/ui';
import { s__, sprintf } from '~/locale';

export default {
  name: 'GeoEmptyState',
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
  <gl-empty-state :title="__('No Design Repositories match this filter')" :svg-path="issuesSvgPath">
    <template v-slot:description>
      <div class="text-center">
        <p>{{ __('Adjust your filters/search criteria above.') }}</p>
        <p v-html="linkText"></p>
      </div>
    </template>
  </gl-empty-state>
</template>
