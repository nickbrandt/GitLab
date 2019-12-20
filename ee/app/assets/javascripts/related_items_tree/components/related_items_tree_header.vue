<script>
import { mapState, mapActions } from 'vuex';

import { GlButton, GlTooltipDirective } from '@gitlab/ui';

import { issuableTypesMap } from 'ee/related_issues/constants';
import { sprintf, s__ } from '~/locale';

import Icon from '~/vue_shared/components/icon.vue';

import EpicActionsSplitButton from './epic_actions_split_button.vue';

export default {
  components: {
    Icon,
    GlButton,
    EpicActionsSplitButton,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  computed: {
    ...mapState(['parentItem', 'descendantCounts']),
    badgeTooltip() {
      return sprintf(s__('Epics|%{epicsCount} epics and %{issuesCount} issues'), {
        epicsCount: this.totalEpicsCount,
        issuesCount: this.totalIssuesCount,
      });
    },
    totalEpicsCount() {
      return this.descendantCounts.openedEpics + this.descendantCounts.closedEpics;
    },
    totalIssuesCount() {
      return this.descendantCounts.openedIssues + this.descendantCounts.closedIssues;
    },
  },
  methods: {
    ...mapActions(['toggleAddItemForm', 'toggleCreateEpicForm', 'setItemInputValue']),
    showAddEpicForm() {
      this.toggleAddItemForm({
        issuableType: issuableTypesMap.EPIC,
        toggleState: true,
      });
    },
    showAddIssueForm() {
      this.setItemInputValue('');
      this.toggleAddItemForm({
        issuableType: issuableTypesMap.ISSUE,
        toggleState: true,
      });
    },
    showCreateEpicForm() {
      this.toggleCreateEpicForm({ toggleState: true });
    },
  },
};
</script>

<template>
  <div class="card-header d-flex px-2">
    <div class="d-inline-flex flex-grow-1 lh-100 align-middle">
      <div
        v-gl-tooltip.hover:tooltipcontainer.bottom
        class="issue-count-badge"
        :title="badgeTooltip"
      >
        <span class="d-inline-flex align-items-center">
          <icon :size="16" name="epic" class="text-secondary mr-1" />
          {{ totalEpicsCount }}
        </span>
        <span class="ml-2 d-inline-flex align-items-center">
          <icon :size="16" name="issues" class="text-secondary mr-1" />
          {{ totalIssuesCount }}
        </span>
      </div>
    </div>
    <div class="d-inline-flex js-button-container">
      <template v-if="parentItem.userPermissions.adminEpic">
        <epic-actions-split-button
          class="qa-add-epics-button"
          @showAddEpicForm="showAddEpicForm"
          @showCreateEpicForm="showCreateEpicForm"
        />

        <slot name="issueActions">
          <gl-button
            class="ml-1 js-add-issues-button qa-add-issues-button"
            size="sm"
            @click="showAddIssueForm"
            >{{ __('Add an issue') }}</gl-button
          >
        </slot>
      </template>
    </div>
  </div>
</template>
