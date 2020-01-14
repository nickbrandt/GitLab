<script>
import { mapState, mapActions } from 'vuex';

import { GlButton, GlTooltip } from '@gitlab/ui';

import { issuableTypesMap } from 'ee/related_issues/constants';

import Icon from '~/vue_shared/components/icon.vue';

import EpicActionsSplitButton from './epic_actions_split_button.vue';

export default {
  components: {
    Icon,
    GlButton,
    GlTooltip,
    EpicActionsSplitButton,
  },
  computed: {
    ...mapState(['parentItem', 'descendantCounts']),
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
      <gl-tooltip :target="() => $refs.countBadge">
        <p class="font-weight-bold m-0">
          {{ __('Epics') }} &#8226;
          <span class="text-secondary-400 font-weight-normal"
            >{{
              sprintf(__('%{openedEpics} open, %{closedEpics} closed'), {
                openedEpics: descendantCounts.openedEpics,
                closedEpics: descendantCounts.closedEpics,
              })
            }}
          </span>
        </p>
        <p class="font-weight-bold m-0">
          {{ __('Issues') }} &#8226;
          <span class="text-secondary-400 font-weight-normal"
            >{{
              sprintf(__('%{openedIssues} open, %{closedIssues} closed'), {
                openedIssues: descendantCounts.openedIssues,
                closedIssues: descendantCounts.closedIssues,
              })
            }}
          </span>
        </p>
      </gl-tooltip>
      <div ref="countBadge" class="issue-count-badge">
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
