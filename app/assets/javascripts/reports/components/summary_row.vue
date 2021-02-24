<script>
import { GlLoadingIcon } from '@gitlab/ui';
import CiIcon from '~/vue_shared/components/ci_icon.vue';
import Popover from '~/vue_shared/components/help_popover.vue';
import { ICON_WARNING } from '../constants';

/**
 * Renders the summary row for each report
 *
 * Used both in MR widget and Pipeline's view for:
 * - Unit tests reports
 * - Security reports
 */

export default {
  name: 'ReportSummaryRow',
  components: {
    CiIcon,
    Popover,
    GlLoadingIcon,
  },
  props: {
    nestedSummary: {
      type: Boolean,
      required: false,
      default: false,
    },
    summary: {
      type: String,
      required: false,
      default: '',
    },
    statusIcon: {
      type: String,
      required: true,
    },
    popoverOptions: {
      type: Object,
      required: false,
      default: null,
    },
  },
  computed: {
    iconStatus() {
      return {
        group: this.statusIcon,
        icon: `status_${this.statusIcon}`,
      };
    },
    rowClasses() {
      if (!this.nestedSummary) {
        return ['report-block-list-issue', 'report-block-list-issue-parent'];
      }
      return [
        'gl-display-flex',
        'gl-pl-7',
        'gl-py-3',
        'gl-pr-3',
        'gl-border-t-solid',
        'gl-border-t-gray-100',
        'gl-border-t-1',
        { 'gl-bg-gray-10': this.statusIcon === ICON_WARNING },
      ];
    },
    statusIconSize() {
      if (!this.nestedSummary) {
        return 24;
      }
      return 16;
    },
  },
};
</script>
<template>
  <div class="gl-align-items-center" :class="rowClasses">
    <div class="gl-mr-3">
      <gl-loading-icon
        v-if="statusIcon === 'loading'"
        css-class="report-block-list-loading-icon"
        size="md"
      />
      <ci-icon v-else :status="iconStatus" :size="statusIconSize" data-testid="summary-row-icon" />
    </div>
    <div class="report-block-list-issue-description">
      <div class="report-block-list-issue-description-text" data-testid="summary-row-description">
        <slot name="summary">{{ summary }}</slot
        ><span v-if="popoverOptions" class="text-nowrap"
          >&nbsp;<popover v-if="popoverOptions" :options="popoverOptions" class="align-top" />
        </span>
      </div>
    </div>
    <div
      v-if="$slots.default"
      class="text-right flex-fill d-flex justify-content-end flex-column flex-sm-row"
    >
      <slot></slot>
    </div>
  </div>
</template>
