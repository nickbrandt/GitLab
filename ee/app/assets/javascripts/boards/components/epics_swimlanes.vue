<script>
import { mapState } from 'vuex';
import { n__ } from '~/locale';
import { GlIcon, GlTooltipDirective } from '@gitlab/ui';
import BoardListHeader from 'ee_else_ce/boards/components/board_list_header.vue';
import EpicLane from './epic_lane.vue';
import IssuesLaneList from './issues_lane_list.vue';

export default {
  components: {
    BoardListHeader,
    EpicLane,
    IssuesLaneList,
    GlIcon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    lists: {
      type: Array,
      required: true,
    },
    disabled: {
      type: Boolean,
      required: true,
    },
    boardId: {
      type: String,
      required: true,
    },
    canAdminList: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    ...mapState(['epics']),
    issuesCount() {
      return this.lists.reduce((total, list) => total + list.issues.length, 0);
    },
    issuesCountTooltipText() {
      return n__(`%d unassigned issue`, `%d unassigned issues`, this.issuesCount);
    },
  },
};
</script>

<template>
  <div
    class="board-swimlanes gl-white-space-nowrap gl-py-5 gl-px-3"
    data_qa_selector="board_epics_swimlanes"
  >
    <div
      v-for="list in lists"
      :key="list.id"
      :class="{
        'is-expandable': list.isExpandable,
        'is-collapsed': !list.isExpanded,
      }"
      class="board gl-px-3 gl-vertical-align-top gl-white-space-normal"
    >
      <board-list-header
        :can-admin-list="canAdminList"
        :list="list"
        :disabled="disabled"
        :board-id="boardId"
        :is-swimlanes-header="true"
      />
    </div>
    <div class="board-epics-swimlanes">
      <epic-lane v-for="epic in epics" :key="epic.id" :epic="epic" :lists="lists" />
      <div
        class="board-lane-unassigned-issues gl-py-5 gl-px-3 gl-display-flex gl-align-items-center"
      >
        <span
          class="gl-mr-3 gl-font-weight-bold gl-white-space-nowrap gl-text-overflow-ellipsis gl-overflow-hidden"
        >
          {{ __('Issues with no epic assigned') }}
        </span>
        <span
          v-gl-tooltip.hover
          :title="issuesCountTooltipText"
          class="gl-display-flex gl-align-items-center gl-text-gray-700"
          tabindex="0"
          :aria-label="issuesCountTooltipText"
          data-testid="issues-lane-issue-count"
        >
          <gl-icon class="gl-mr-2 gl-flex-shrink-0" name="issues" aria-hidden="true" />
          <span aria-hidden="true">{{ issuesCount }}</span>
        </span>
      </div>
      <div class="gl-display-flex">
        <issues-lane-list
          v-for="list in lists"
          :key="`${list.id}-issues`"
          :list="list"
          :issues="list.issues"
        />
      </div>
    </div>
  </div>
</template>
