<script>
import {
  GlDrawer,
  GlLabel,
  GlButton,
  GlFormInput,
  GlAvatarLink,
  GlAvatarLabeled,
  GlLink,
} from '@gitlab/ui';
import { mapActions, mapState } from 'vuex';
import { __ } from '~/locale';
import autofocusonshow from '~/vue_shared/directives/autofocusonshow';
import boardsStoreEE from '../stores/boards_store_ee';
import flash from '~/flash';

// NOTE: need to revisit how we handle headerHeight, because we have so many different header and footer options.
export default {
  headerHeight: process.env.NODE_ENV === 'development' ? '75px' : '40px',
  listSettingsText: __('List Settings'),
  assignee: 'assignee',
  milestone: 'milestone',
  label: 'label',
  labelListText: __('Label'),
  labelMilestoneText: __('Milestone'),
  labelAssigneeText: __('Assignee'),
  editLinkText: __('Edit'),
  noneText: __('None'),
  wipLimitText: __('Work in Progress Limit'),
  components: {
    GlDrawer,
    GlLabel,
    GlButton,
    GlFormInput,
    GlAvatarLink,
    GlAvatarLabeled,
    GlLink,
  },
  directives: {
    autofocusonshow,
  },
  data() {
    return {
      edit: false,
      currentWipLimit: 0,
      updating: false,
    };
  },
  computed: {
    ...mapState(['activeListId']),
    activeList() {
      /*
        Warning: Though a computed property it is not reactive because we are
        referencing a List Model class. Reactivity only applies to plain JS objects
      */

      return boardsStoreEE.store.state.lists.find(({ id }) => id === this.activeListId);
    },
    isSidebarOpen() {
      return this.activeListId > 0;
    },
    activeListLabel() {
      return this.activeList.label;
    },
    activeListMilestone() {
      return this.activeList.milestone;
    },
    activeListAssignee() {
      return this.activeList.assignee;
    },
    activeListWipLimit() {
      return this.activeList.maxIssueCount === 0
        ? this.$options.noneText
        : this.activeList.maxIssueCount;
    },
    boardListType() {
      return this.activeList.type || null;
    },
    listTypeTitle() {
      switch (this.boardListType) {
        case this.$options.milestone: {
          return this.$options.labelMilestoneText;
        }
        case this.$options.label: {
          return this.$options.labelListText;
        }
        case this.$options.assignee: {
          return this.$options.labelAssigneeText;
        }
        default: {
          return '';
        }
      }
    },
  },
  methods: {
    ...mapActions(['setActiveListId', 'updateListWipLimit']),
    closeSidebar() {
      this.edit = false;
      this.setActiveListId(0);
    },
    showInput() {
      this.edit = true;
      this.currentWipLimit = this.activeList.maxIssueCount;
    },
    resetStateAfterUpdate() {
      this.edit = false;
      this.updating = false;
      this.currentWipLimit = 0;
    },
    offFocus() {
      if (this.currentWipLimit !== this.activeList.maxIssueCount) {
        this.updating = true;
        // NOTE: Need a ref to activeListId in case the user closes the drawer.
        const id = this.activeListId;

        this.updateListWipLimit({ maxIssueCount: this.currentWipLimit, id })
          .then(({ config }) => {
            boardsStoreEE.setMaxIssueCountOnList(id, JSON.parse(config.data).list.max_issue_count);
            this.resetStateAfterUpdate();
          })
          .catch(() => {
            this.resetStateAfterUpdate();
            this.setActiveListId(0);
            flash(__('Something went wrong while updating your list settings'));
          });
      } else {
        this.edit = false;
      }
    },
    onEnter() {
      this.offFocus();
    },
  },
};
</script>

<template>
  <gl-drawer
    class="js-board-settings-sidebar"
    :open="isSidebarOpen"
    :header-height="$options.headerHeight"
    @close="closeSidebar"
  >
    <template #header>{{ $options.listSettingsText }}</template>
    <template v-if="isSidebarOpen">
      <div class="d-flex flex-column align-items-start">
        <label class="js-list-label">{{ listTypeTitle }}</label>
        <template v-if="boardListType === $options.label">
          <gl-label
            :title="activeListLabel.title"
            :background-color="activeListLabel.color"
            color="light"
          />
        </template>
        <template v-else-if="boardListType === $options.assignee">
          <gl-avatar-link class="js-assignee" :href="activeListAssignee.webUrl">
            <gl-avatar-labeled
              :size="32"
              :label="activeListAssignee.name"
              :sub-label="`@${activeListAssignee.username}`"
              :src="activeListAssignee.avatar"
            />
          </gl-avatar-link>
        </template>
        <template v-else-if="boardListType === $options.milestone">
          <gl-link class="js-milestone" :href="activeListMilestone.webUrl">{{
            activeListMilestone.title
          }}</gl-link>
        </template>
      </div>
      <div class="d-flex justify-content-between">
        <div>
          <label>{{ $options.wipLimitText }}</label>
          <gl-form-input
            v-if="edit"
            v-model.number="currentWipLimit"
            v-autofocusonshow
            :disabled="updating"
            type="number"
            min="0"
            trim
            @keydown.enter.native="onEnter"
            @blur="offFocus"
          />
          <p v-else class="js-wip-limit bold">{{ activeListWipLimit }}</p>
        </div>
        <gl-button class="h-100 border-0 gl-line-height-14" variant="link" @click="showInput">
          {{ $options.editLinkText }}
        </gl-button>
      </div>
    </template>
  </gl-drawer>
</template>
