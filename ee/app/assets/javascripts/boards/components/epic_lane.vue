<script>
import { GlButton, GlIcon, GlLink, GlPopover, GlTooltipDirective } from '@gitlab/ui';
import { __, n__, sprintf } from '~/locale';
import timeagoMixin from '~/vue_shared/mixins/timeago';
import { formatDate } from '~/lib/utils/datetime_utility';
import { statusType } from '../../epic/constants';
import IssuesLaneList from './issues_lane_list.vue';

export default {
  components: {
    GlButton,
    GlIcon,
    GlLink,
    GlPopover,
    IssuesLaneList,
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
    lists: {
      type: Array,
      required: true,
    },
  },
  data() {
    return {
      isExpanded: true,
    };
  },
  computed: {
    isOpen() {
      return this.epic.state === statusType.open;
    },
    chevronTooltip() {
      return this.isExpanded ? __('Collapse') : __('Expand');
    },
    chevronIcon() {
      return this.isExpanded ? 'chevron-down' : 'chevron-right';
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
  methods: {
    epicIssuesForList(listIssues) {
      return this.epic.issues.filter(epicIssue =>
        Boolean(listIssues.find(listIssue => String(listIssue.iid) === epicIssue.iid)),
      );
    },
    toggleExpanded() {
      this.isExpanded = !this.isExpanded;
    },
  },
};
</script>

<template>
  <div>
    <div class="board-epic-lane gl-sticky gl-left-0 gl-display-inline-block gl-max-w-full">
      <div class="gl-py-5 gl-px-3 gl-display-flex gl-align-items-center">
        <gl-button
          v-gl-tooltip.hover.right
          :aria-label="chevronTooltip"
          :title="chevronTooltip"
          :icon="chevronIcon"
          class="gl-mr-2 gl-cursor-pointer"
          variant="link"
          data-testid="epic-lane-chevron"
          @click="toggleExpanded"
        />
        <gl-icon
          class="gl-mr-2 gl-flex-shrink-0"
          :class="stateIconClass"
          :name="epicIcon"
          :aria-label="stateText"
        />
        <h4
          ref="epicTitle"
          class="gl-mr-3 gl-font-weight-bold gl-font-base gl-white-space-nowrap gl-text-overflow-ellipsis gl-overflow-hidden"
        >
          {{ epic.title }}
        </h4>
        <gl-popover :target="() => $refs.epicTitle" triggers="hover" placement="top">
          <template #title
            >{{ epic.title }} &middot; {{ epic.reference }}</template
          >
          <div>{{ epicTimeAgoString }}</div>
          <div class="gl-mb-2">{{ epicDateString }}</div>
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
    </div>
    <div v-if="isExpanded" class="gl-display-flex">
      <issues-lane-list
        v-for="list in lists"
        :key="`${list.id}-issues`"
        :list="list"
        :issues="epicIssuesForList(list.issues)"
      />
    </div>
  </div>
</template>
