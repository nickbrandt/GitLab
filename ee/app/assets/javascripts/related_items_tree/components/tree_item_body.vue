<script>
import { mapState, mapActions } from 'vuex';
import {
  GlTooltipDirective,
  GlModalDirective,
  GlLink,
  GlIcon,
  GlDeprecatedButton,
  GlTooltip,
} from '@gitlab/ui';
import { isEmpty } from 'lodash';

import ItemWeight from 'ee/boards/components/issue_card_weight.vue';
import { __ } from '~/locale';

import ItemMilestone from '~/vue_shared/components/issue/issue_milestone.vue';
import ItemAssignees from '~/vue_shared/components/issue/issue_assignees.vue';
import ItemDueDate from '~/boards/components/issue_due_date.vue';

import EpicHealthStatus from './epic_health_status.vue';
import IssueHealthStatus from './issue_health_status.vue';

import StateTooltip from './state_tooltip.vue';

import { ChildType, ChildState, itemRemoveModalId } from '../constants';

export default {
  itemRemoveModalId,
  components: {
    GlIcon,
    GlLink,
    GlTooltip,
    GlDeprecatedButton,
    StateTooltip,
    ItemMilestone,
    ItemAssignees,
    ItemDueDate,
    ItemWeight,
    EpicHealthStatus,
    IssueHealthStatus,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
    GlModalDirective,
  },
  props: {
    parentItem: {
      type: Object,
      required: true,
    },
    item: {
      type: Object,
      required: true,
    },
  },
  computed: {
    ...mapState(['childrenFlags', 'userSignedIn', 'allowSubEpics']),
    itemReference() {
      return this.item.reference;
    },
    itemWebPath() {
      // Here, GraphQL API (during item fetch) returns `webPath`
      // and Rails API (during item add) returns `path`,
      // we need to make both accessible.
      return this.item.path || this.item.webPath;
    },
    isOpen() {
      return this.item.state === ChildState.Open;
    },
    isClosed() {
      return this.item.state === ChildState.Closed;
    },
    hasMilestone() {
      return !isEmpty(this.item.milestone);
    },
    hasAssignees() {
      return this.item.assignees && this.item.assignees.length > 0;
    },
    stateText() {
      return this.isOpen ? __('Opened') : __('Closed');
    },
    stateIconName() {
      return this.item.type === ChildType.Epic ? 'epic' : 'issues';
    },
    stateIconClass() {
      return this.isOpen ? 'issue-token-state-icon-open' : 'issue-token-state-icon-closed';
    },
    itemId() {
      return this.itemReference.split(this.item.pathIdSeparator).pop();
    },
    itemHierarchy() {
      return this.itemPath + this.item.pathIdSeparator + this.itemId;
    },
    computedPath() {
      return this.itemWebPath.length ? this.itemWebPath : null;
    },
    itemActionInProgress() {
      return (
        this.childrenFlags[this.itemReference].itemChildrenFetchInProgress ||
        this.childrenFlags[this.itemReference].itemRemoveInProgress
      );
    },
    showEmptySpacer() {
      return !this.parentItem.userPermissions.adminEpic && this.userSignedIn;
    },
    totalEpicsCount() {
      const { descendantCounts: { openedEpics = 0, closedEpics = 0 } = {} } = this.item;

      return openedEpics + closedEpics;
    },
    totalIssuesCount() {
      const { descendantCounts: { openedIssues = 0, closedIssues = 0 } = {} } = this.item;

      return openedIssues + closedIssues;
    },
    isEpic() {
      return this.item.type === ChildType.Epic;
    },
    isIssue() {
      return this.item.type === ChildType.Issue;
    },
  },
  methods: {
    ...mapActions(['setRemoveItemModalProps']),
    handleRemoveClick() {
      const { parentItem, item } = this;

      this.setRemoveItemModalProps({
        parentItem,
        item,
      });
    },
  },
};
</script>

<template>
  <div class="card card-slim sortable-row flex-grow-1">
    <div
      class="item-body card-body d-flex align-items-center p-2 pl-xl-3"
      :class="{
        'p-xl-1': userSignedIn,
        'item-logged-out pt-xl-2 pb-xl-2': !userSignedIn,
        'item-closed': isClosed,
      }"
    >
      <div class="item-contents d-flex align-items-center flex-wrap flex-grow-1 flex-xl-nowrap">
        <div class="d-flex flex-column flex-grow-1 item-title-wrapper">
          <div class="item-title d-flex align-items-center mb-1 mb-xl-0">
            <gl-icon
              ref="stateIconMd"
              :class="stateIconClass"
              :name="stateIconName"
              :aria-label="stateText"
            />
            <state-tooltip
              :get-target-ref="() => $refs.stateIconMd"
              :path="itemHierarchy"
              :is-open="isOpen"
              :state="item.state"
              :created-at="item.createdAt"
              :closed-at="item.closedAt || ''"
            />
            <gl-icon
              v-if="item.confidential"
              v-gl-tooltip.hover
              :title="__('Confidential')"
              :aria-label="__('Confidential')"
              name="eye-slash"
              class="confidential-icon append-right-4 align-self-baseline align-self-md-auto mt-xl-0"
            />
            <gl-link :href="computedPath" class="sortable-link">{{ item.title }}</gl-link>
          </div>
        </div>

        <div
          class="item-meta d-flex flex-wrap mt-xl-0 justify-content-xl-end flex-xl-nowrap align-items-center"
        >
          <gl-tooltip v-if="isEpic" :target="() => $refs.countBadge">
            <p v-if="allowSubEpics" class="font-weight-bold m-0">
              {{ __('Epics') }} &#8226;
              <span class="text-secondary-400 font-weight-normal"
                >{{
                  sprintf(__('%{openedEpics} open, %{closedEpics} closed'), {
                    openedEpics: item.descendantCounts && item.descendantCounts.openedEpics,
                    closedEpics: item.descendantCounts && item.descendantCounts.closedEpics,
                  })
                }}
              </span>
            </p>
            <p class="font-weight-bold m-0">
              {{ __('Issues') }} &#8226;
              <span class="text-secondary-400 font-weight-normal"
                >{{
                  sprintf(__('%{openedIssues} open, %{closedIssues} closed'), {
                    openedIssues: item.descendantCounts && item.descendantCounts.openedIssues,
                    closedIssues: item.descendantCounts && item.descendantCounts.closedIssues,
                  })
                }}
              </span>
            </p>
          </gl-tooltip>

          <div v-if="isEpic" ref="countBadge" class="issue-count-badge text-secondary">
            <span v-if="allowSubEpics" class="d-inline-flex align-items-center">
              <gl-icon name="epic" class="mr-1" />
              {{ totalEpicsCount }}
            </span>
            <span class="ml-2 bullet-separator">&bull;</span>
            <span class="d-inline-flex align-items-center" :class="{ 'ml-2': allowSubEpics }">
              <gl-icon name="issues" class="mr-1" />
              {{ totalIssuesCount }}
            </span>
            <span class="ml-2 bullet-separator">&bull;</span>
          </div>

          <div v-if="item.healthStatus" class="item-health-status mr-2">
            <epic-health-status v-if="isEpic" :health-status="item.healthStatus" />
            <issue-health-status v-else-if="isIssue" :health-status="item.healthStatus" />
          </div>

          <div
            class="item-meta-child d-flex align-items-center order-0 flex-wrap mt-2 mt-md-0 flex-xl-nowrap"
          >
            <!-- This bullet is for Milestone -->
            <span v-if="item.healthStatus && hasMilestone" class="bullet-separator mr-2"
              >&bull;</span
            >

            <item-milestone
              v-if="hasMilestone"
              :milestone="item.milestone"
              class="d-flex align-items-center item-milestone mr-2"
            />

            <!-- This bullet is for Due Date -->
            <span
              v-if="(hasMilestone || item.healthStatus) && item.dueDate"
              class="mr-2 bullet-separator"
              >&bull;</span
            >

            <item-due-date
              v-if="item.dueDate"
              :date="item.dueDate"
              tooltip-placement="top"
              css-class="item-due-date d-flex align-items-center mr-2"
            />

            <!-- This bullet is for Weight -->
            <span
              v-if="(item.dueDate || hasMilestone || item.healthStatus) && item.weight"
              class="mr-2 bullet-separator"
              >&bull;</span
            >

            <item-weight
              v-if="item.weight"
              :weight="item.weight"
              class="item-weight d-flex align-items-center mr-2"
              tag-name="span"
            />
          </div>

          <!-- This bullet is for Assignees -->
          <span
            v-if="
              (item.dueDate || hasMilestone || item.healthStatus || item.weight) && hasAssignees
            "
            class="mr-2 bullet-separator"
            >&bull;</span
          >
          <item-assignees
            v-if="hasAssignees"
            :assignees="item.assignees"
            class="item-assignees d-inline-flex align-items-center align-self-end mr-2 mt-2 mt-md-0 mt-xl-0 mr-xl-1 mb-md-0 order-2 flex-xl-grow-0"
          />
        </div>
        <gl-deprecated-button
          v-if="parentItem.userPermissions.adminEpic"
          v-gl-tooltip.hover
          v-gl-modal-directive="$options.itemRemoveModalId"
          :title="__('Remove')"
          :disabled="itemActionInProgress"
          class="btn-svg btn-item-remove js-issue-item-remove-button qa-remove-issue-button"
          @click="handleRemoveClick"
        >
          <gl-icon name="close" class="btn-item-remove-icon" />
        </gl-deprecated-button>
        <span v-if="showEmptySpacer" class="p-3"></span>
      </div>
    </div>
  </div>
</template>
