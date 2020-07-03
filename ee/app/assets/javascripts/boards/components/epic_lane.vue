<script>
import { GlIcon, GlLink, GlPopover, GlTooltipDirective } from '@gitlab/ui';
import { __, n__, sprintf } from '~/locale';
import timeagoMixin from '~/vue_shared/mixins/timeago';
import { formatDate } from '~/lib/utils/datetime_utility';
import { statusType } from '../../epic/constants';

export default {
  components: {
    GlIcon,
    GlLink,
    GlPopover,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [timeagoMixin],
  props: {
    epic: {
      type: Object,
      required: true,
    },
  },
  computed: {
    isOpen() {
      return this.epic.state === statusType.open;
    },
    stateText() {
      return this.isOpen ? __('Opened') : __('Closed');
    },
    epicIcon() {
      return this.isOpen ? 'epic' : 'epic-closed';
    },
    stateIconClass() {
      return this.isOpen ? 'gl-text-green-500' : 'gl-text-blue-500';
    },
    issuesCount() {
      const { openedIssues, closedIssues } = this.epic.descendantCounts;
      return openedIssues + closedIssues;
    },
    issuesCountTooltipText() {
      return n__(`%d issue in this group`, `%d issues in this group`, this.issuesCount);
    },
    epicTimeAgoString() {
      return this.isOpen
        ? sprintf(__(`Opened %{epicTimeagoDate}`), {
            epicTimeagoDate: this.timeFormatted(this.epic.createdAt),
          })
        : sprintf(__(`Closed %{epicTimeagoDate}`), {
            epicTimeagoDate: this.timeFormatted(this.epic.closedAt),
          });
    },
    epicDateString() {
      return formatDate(this.epic.createdAt);
    },
  },
};
</script>

<template>
  <div class="board-epic-lane gl-py-5 gl-px-3 gl-display-flex gl-align-items-center">
    <gl-icon
      class="gl-mr-2 gl-flex-shrink-0"
      :class="stateIconClass"
      :name="epicIcon"
      :aria-label="stateText"
    />
    <span
      ref="epicTitle"
      class="gl-mr-3 gl-font-weight-bold gl-white-space-nowrap gl-text-overflow-ellipsis gl-overflow-hidden"
    >
      {{ epic.title }}
    </span>
    <gl-popover :target="() => $refs.epicTitle" triggers="hover" placement="top">
      <template #title
        >{{ epic.title }} &middot; {{ epic.reference }}</template
      >
      <p class="gl-m-0">{{ epicTimeAgoString }}</p>
      <p class="gl-mb-2">{{ epicDateString }}</p>
      <gl-link :href="epic.webUrl" class="gl-font-sm">{{ __('Go to epic') }}</gl-link>
    </gl-popover>
    <span
      v-gl-tooltip.hover
      :title="issuesCountTooltipText"
      class="gl-display-flex gl-align-items-center gl-text-gray-700"
      tabindex="0"
      :aria-label="issuesCountTooltipText"
      data-testid="epic-lane-issue-count"
    >
      <gl-icon class="gl-mr-2 gl-flex-shrink-0" name="issues" aria-hidden="true" />
      <span aria-hidden="true">{{ issuesCount }}</span>
    </span>
  </div>
</template>
