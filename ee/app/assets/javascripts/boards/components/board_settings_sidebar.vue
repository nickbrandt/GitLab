<script>
import {
  GlDrawer,
  GlLabel,
  GlDeprecatedButton,
  GlFormInput,
  GlAvatarLink,
  GlAvatarLabeled,
  GlLink,
} from '@gitlab/ui';
import { mapActions, mapState } from 'vuex';
import { __, n__ } from '~/locale';
import autofocusonshow from '~/vue_shared/directives/autofocusonshow';
import boardsStoreEE from '../stores/boards_store_ee';
import eventHub from '~/sidebar/event_hub';
import flash from '~/flash';
import { isScopedLabel } from '~/lib/utils/common_utils';

// NOTE: need to revisit how we handle headerHeight, because we have so many different header and footer options.
export default {
  headerHeight: process.env.NODE_ENV === 'development' ? '75px' : '40px',
  listSettingsText: __('List settings'),
  assignee: 'assignee',
  milestone: 'milestone',
  label: 'label',
  labelListText: __('Label'),
  labelMilestoneText: __('Milestone'),
  labelAssigneeText: __('Assignee'),
  editLinkText: __('Edit'),
  noneText: __('None'),
  wipLimitText: __('Work in progress Limit'),
  removeLimitText: __('Remove limit'),
  inputPlaceholderText: __('Enter number of issues'),
  components: {
    GlDrawer,
    GlLabel,
    GlDeprecatedButton,
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
      currentWipLimit: null,
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
    wipLimitTypeText() {
      return n__('%d issue', '%d issues', this.activeList.maxIssueCount);
    },
    wipLimitIsSet() {
      return this.activeList.maxIssueCount !== 0;
    },
    activeListWipLimit() {
      return this.activeList.maxIssueCount === 0 ? this.$options.noneText : this.wipLimitTypeText;
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
  created() {
    eventHub.$on('sidebar.closeAll', this.closeSidebar);
  },
  beforeDestroy() {
    eventHub.$off('sidebar.closeAll', this.closeSidebar);
  },
  methods: {
    ...mapActions(['setActiveListId', 'updateListWipLimit']),
    closeSidebar() {
      this.edit = false;
      this.setActiveListId(0);
    },
    showInput() {
      this.edit = true;
      this.currentWipLimit =
        this.activeList.maxIssueCount > 0 ? this.activeList.maxIssueCount : null;
    },
    resetStateAfterUpdate() {
      this.edit = false;
      this.updating = false;
      this.currentWipLimit = null;
    },
    offFocus() {
      if (this.currentWipLimit !== this.activeList.maxIssueCount && this.currentWipLimit !== null) {
        this.updating = true;
        // need to reassign bc were clearing the ref in resetStateAfterUpdate.
        const wipLimit = this.currentWipLimit;
        const id = this.activeListId;

        this.updateListWipLimit({ maxIssueCount: this.currentWipLimit, id })
          .then(() => {
            boardsStoreEE.setMaxIssueCountOnList(id, wipLimit);
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
    clearWipLimit() {
      this.updateListWipLimit({ maxIssueCount: 0, id: this.activeListId })
        .then(() => {
          boardsStoreEE.setMaxIssueCountOnList(this.activeListId, 0);
          this.resetStateAfterUpdate();
        })
        .catch(() => {
          this.resetStateAfterUpdate();
          this.setActiveListId(0);
          flash(__('Something went wrong while updating your list settings'));
        });
    },
    handleWipLimitChange(wipLimit) {
      if (wipLimit === '') {
        this.currentWipLimit = null;
      } else {
        this.currentWipLimit = Number(wipLimit);
      }
    },
    onEnter() {
      this.offFocus();
    },
    showScopedLabels(label) {
      return boardsStoreEE.store.scopedLabels.enabled && isScopedLabel(label);
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
            :scoped="showScopedLabels(activeListLabel)"
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
      <div class="d-flex justify-content-between flex-column">
        <div class="d-flex justify-content-between align-items-center mb-2">
          <label class="m-0">{{ $options.wipLimitText }}</label>
          <gl-deprecated-button
            class="js-edit-button h-100 border-0 gl-line-height-14-deprecated-no-really-do-not-use-me text-dark"
            variant="link"
            @click="showInput"
            >{{ $options.editLinkText }}</gl-deprecated-button
          >
        </div>
        <gl-form-input
          v-if="edit"
          v-autofocusonshow
          :value="currentWipLimit"
          :disabled="updating"
          :placeholder="$options.inputPlaceholderText"
          trim
          number
          type="number"
          min="0"
          @input="handleWipLimitChange"
          @keydown.enter.native="onEnter"
          @blur="offFocus"
        />
        <div v-else class="d-flex align-items-center">
          <p class="js-wip-limit bold m-0 text-secondary">{{ activeListWipLimit }}</p>
          <template v-if="wipLimitIsSet">
            <span class="m-1">-</span>
            <gl-deprecated-button
              class="js-remove-limit h-100 border-0 gl-line-height-14-deprecated-no-really-do-not-use-me text-secondary"
              variant="link"
              @click="clearWipLimit"
              >{{ $options.removeLimitText }}</gl-deprecated-button
            >
          </template>
        </div>
      </div>
    </template>
  </gl-drawer>
</template>
