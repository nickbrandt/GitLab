<script>
import BoardListHeader from 'ee_else_ce/boards/components/board_list_header.vue';

export default {
  components: {
    BoardListHeader,
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
    issueLinkBase: {
      type: String,
      required: true,
    },
    rootPath: {
      type: String,
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
    groupId: {
      type: Number,
      required: false,
      default: null,
    },
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
      class="board gl-h-full gl-px-3 gl-vertical-align-top gl-white-space-normal"
    >
      <board-list-header
        :can-admin-list="canAdminList"
        :list="list"
        :disabled="disabled"
        :board-id="boardId"
        :is-swimlanes-header="true"
      />
    </div>
  </div>
</template>
