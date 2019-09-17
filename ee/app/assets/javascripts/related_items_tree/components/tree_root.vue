<script>
import { mapState, mapActions } from 'vuex';
import Draggable from 'vuedraggable';
import { GlButton, GlLoadingIcon } from '@gitlab/ui';

import { ChildType } from '../constants';
import TreeDragAndDropMixin from '../mixins/tree_dd_mixin';

export default {
  components: {
    Draggable,
    GlButton,
    GlLoadingIcon,
  },
  mixins: [TreeDragAndDropMixin],
  props: {
    parentItem: {
      type: Object,
      required: true,
    },
    children: {
      type: Array,
      required: true,
    },
  },
  data() {
    return {
      fetchInProgress: false,
    };
  },
  computed: {
    ...mapState(['childrenFlags']),
    currentItemIssuesBeginAtIndex() {
      return this.children.findIndex(item => item.type === ChildType.Issue);
    },
    hasMoreChildren() {
      const flags = this.childrenFlags[this.parentItem.reference];

      return flags.hasMoreEpics || flags.hasMoreIssues;
    },
  },
  methods: {
    ...mapActions(['fetchNextPageItems', 'reorderItem']),
    handleShowMoreClick() {
      this.fetchInProgress = true;
      this.fetchNextPageItems({
        parentItem: this.parentItem,
      })
        .then(() => {
          this.fetchInProgress = false;
        })
        .catch(() => {
          this.fetchInProgress = false;
        });
    },
  },
};
</script>

<template>
  <draggable
    tag="ul"
    v-bind="dragOptions"
    class="list-unstyled related-items-list tree-root"
    ghost-class="tree-item-drag-active"
    :data-parent-reference="parentItem.reference"
    :value="children"
    :move="handleDragOnMove"
    @start="handleDragOnStart"
    @end="handleDragOnEnd"
  >
    <tree-item v-for="item in children" :key="item.id" :parent-item="parentItem" :item="item" />
    <li v-if="hasMoreChildren" class="tree-item list-item pt-0 pb-0 d-flex justify-content-center">
      <gl-button
        v-if="!fetchInProgress"
        class="d-inline-block mb-2"
        variant="link"
        @click="handleShowMoreClick($event)"
        >{{ s__('Epics|Show more') }}</gl-button
      >
      <gl-loading-icon v-else size="sm" class="mt-1 mb-1" />
    </li>
  </draggable>
</template>
