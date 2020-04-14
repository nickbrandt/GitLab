<script>
import {
  GlPopover,
  GlIcon,
  GlLink,
  GlNewButton,
  GlTooltipDirective,
  GlLoadingIcon,
} from '@gitlab/ui';
import { s__ } from '~/locale';
import createFlash from '~/flash';
import axios from '~/lib/utils/axios_utils';
import { formatDate } from '~/lib/utils/datetime_utility';
import pollUntilComplete from '~/lib/utils/poll_until_complete';

export const STORAGE_KEY = 'vulnerability_csv_export_popover_dismissed';

export default {
  components: {
    GlIcon,
    GlNewButton,
    GlPopover,
    GlLink,
    GlLoadingIcon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    vulnerabilitiesExportEndpoint: {
      type: String,
      required: true,
    },
  },
  data: () => ({
    isPreparingCsvExport: false,
    showPopover: localStorage.getItem(STORAGE_KEY) !== 'true',
  }),
  methods: {
    closePopover() {
      this.showPopover = false;

      try {
        localStorage.setItem(STORAGE_KEY, 'true');
      } catch (e) {
        // Ignore the error - this is just a safety measure.
      }
    },
    initiateCsvExport() {
      this.isPreparingCsvExport = true;
      this.closePopover();

      axios
        .post(this.vulnerabilitiesExportEndpoint)
        .then(({ data }) => pollUntilComplete(data._links.self))
        .then(({ data }) => {
          const anchor = document.createElement('a');
          anchor.download = `csv-export-${formatDate(new Date(), 'isoDateTime')}.csv`;
          anchor.href = data._links.download;
          anchor.click();
        })
        .catch(() => {
          createFlash(s__('SecurityDashboard|There was an error while generating the report.'));
        })
        .finally(() => {
          this.isPreparingCsvExport = false;
        });
    },
  },
};
</script>
<template>
  <gl-new-button
    ref="csvExportButton"
    v-gl-tooltip.hover
    class="align-self-center"
    :title="__('Export as CSV')"
    :loading="isPreparingCsvExport"
    @click="initiateCsvExport"
  >
    <gl-icon
      v-if="!isPreparingCsvExport"
      ref="exportIcon"
      name="export"
      class="mr-0 position-top-0"
    />
    <gl-loading-icon v-else />
    <gl-popover
      ref="popover"
      :target="() => $refs.csvExportButton.$el"
      :show="showPopover"
      placement="left"
      triggers="manual"
    >
      <p class="gl-font-size-14">
        {{ __('You can now export your security dashboard to a CSV report.') }}
      </p>
      <gl-link
        ref="popoverExternalLink"
        target="_blank"
        href="https://gitlab.com/gitlab-org/gitlab/issues/197111"
        class="d-flex align-items-center mb-3"
      >
        {{ __('More information and share feedback') }}
        <gl-icon name="external-link" :size="12" class="ml-1" />
      </gl-link>
      <gl-new-button ref="popoverButton" class="w-100" @click="closePopover">
        {{ __('Got it!') }}
      </gl-new-button>
    </gl-popover>
  </gl-new-button>
</template>
