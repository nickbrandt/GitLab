<script>
import { GlIcon, GlTooltipDirective } from '@gitlab/ui';
import { __, sprintf } from '~/locale';

export default {
  components: {
    GlIcon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    epic: {
      type: Object,
      required: true,
    },
  },
  computed: {
    stateText() {
      return this.epic.state === 'opened' ? __('Opened') : __('Closed');
    },
    stateIconClass() {
      return this.epic.state === 'opened' ? 'gl-text-green-500' : 'gl-text-blue-500';
    },
    issuesCount() {
      const { openedIssues, closedIssues } = this.epic.descendantCounts;
      return openedIssues + closedIssues;
    },
    issuesCountTooltipText() {
      return sprintf(__(`%{issuesCount} issues in this group`), { issuesCount: this.issuesCount });
    },
  },
};
</script>

<template>
  <div class="board-epic-lane gl-py-5 gl-px-3 gl-display-flex gl-align-items-center">
    <gl-icon
      class="gl-mr-2 gl-flex-shrink-0"
      :class="stateIconClass"
      name="epic"
      :aria-label="stateText"
    />
    <span
      v-gl-tooltip.hover
      :title="epic.title"
      class="gl-mr-3 gl-font-weight-bold gl-white-space-nowrap gl-text-overflow-ellipsis gl-overflow-hidden"
    >
      {{ epic.title }}
    </span>
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
