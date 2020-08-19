<script>
import { mapState } from 'vuex';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import EpicsSwimlanes from 'ee_component/boards/components/epics_swimlanes.vue';
import BoardContentLayout from '~/boards/components/board_content_layout.vue';
import BoardColumn from 'ee_component/boards/components/board_column.vue';

export default {
  components: {
    BoardColumn,
    BoardContentLayout,
    EpicsSwimlanes,
  },
  mixins: [glFeatureFlagMixin()],
  computed: {
    ...mapState(['isShowingEpicsSwimlanes', 'boardLists']),
    isSwimlanesOn() {
      return this.glFeatures.boardsWithSwimlanes && this.isShowingEpicsSwimlanes;
    },
  },
};
</script>

<template>
  <board-content-layout v-bind="$attrs" :is-swimlanes-off="!isSwimlanesOn">
    <template
      #board-content-decoration="{ lists, canAdminList, disabled, boardId, groupId, issueLinkBase, rootPath }"
    >
      <epics-swimlanes
        v-if="isSwimlanesOn"
        ref="swimlanes"
        :lists="boardLists"
        :can-admin-list="canAdminList"
        :disabled="disabled"
        :board-id="boardId"
        :group-id="groupId"
        :root-path="rootPath"
      />
      <board-column
        v-for="list in lists"
        v-else
        :key="list.id"
        ref="board"
        :can-admin-list="canAdminList"
        :group-id="groupId"
        :list="list"
        :disabled="disabled"
        :issue-link-base="issueLinkBase"
        :root-path="rootPath"
        :board-id="boardId"
      />
    </template>
  </board-content-layout>
</template>
