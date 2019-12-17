<script>
import { GlDrawer, GlLabel } from '@gitlab/ui';
import { __ } from '~/locale';
import boardsStore from '~/boards/stores/boards_store';
import { mapActions, mapState } from 'vuex';

// NOTE: need to revisit how we handle headerHeight, because we have so many different header and footer options.
export default {
  headerHeight: process.env.NODE_ENV === 'development' ? '75px' : '40px',
  components: {
    GlDrawer,
    GlLabel,
  },
  computed: {
    ...mapState(['activeListId']),
    isOpen() {
      return this.activeListId > 0;
    },
    activeList() {
      return boardsStore.state.lists.find(({ id }) => id === this.activeListId);
    },
    activeListLabel() {
      if (this.activeList) {
        return this.activeList.label;
      }

      return { color: '', title: '' };
    },
    listSettingsText() {
      return __('List Settings');
    },
    labelListText() {
      return __('Label List');
    },
  },
  methods: {
    ...mapActions(['setActiveListId']),
    closeSidebar() {
      this.setActiveListId(0);
    },
  },
};
</script>

<template>
  <gl-drawer :open="isOpen" :header-height="$options.headerHeight" @close="closeSidebar">
    <template #header>{{ listSettingsText }}</template>
    <template>
      <div class="js-board-settings-sidebar d-flex flex-column align-items-start">
        <label>{{ labelListText }}</label>
        <gl-label
          :title="activeListLabel.title"
          :background-color="activeListLabel.color"
          color="light"
        />
      </div>
    </template>
  </gl-drawer>
</template>
