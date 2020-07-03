<script>
import { mapState } from 'vuex';
import BoardListHeader from 'ee_else_ce/boards/components/board_list_header.vue';
import EpicLane from './epic_lane.vue';

export default {
  components: {
    BoardListHeader,
    EpicLane,
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
  },
};
</script>

<template>
  <div
    class="board-epics-swimlanes gl-white-space-nowrap gl-py-5 gl-px-3"
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
    <epic-lane v-for="epic in epics" :key="epic.id" :epic="epic" />
    <div class="board-lane-unassigned-issue gl-py-5 gl-px-3 gl-display-flex gl-align-items-center">
      <span
        class="gl-mr-3 gl-font-weight-bold gl-white-space-nowrap gl-text-overflow-ellipsis gl-overflow-hidden"
      >
        {{ __('Issues with no epics assigned') }}
      </span>
    </div>
  </div>
</template>
