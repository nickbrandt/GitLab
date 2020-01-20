<script>
import SplitButton from '~/vue_shared/components/split_button.vue';

import { __ } from '~/locale';

const actionItems = [
  {
    title: __('Add an issue'),
    description: __('Add an existing issue to the epic.'),
    eventName: 'showAddIssueForm',
  },
  {
    title: __('Create an issue'),
    description: __('Create a new issue and add it to the epic.'),
    eventName: 'showCreateIssueForm',
  },
];

export default {
  actionItems,

  components: {
    SplitButton,
  },
  methods: {
    change(item) {
      this.$emit(item.eventName);
    },
  },
};
</script>

<template>
  <split-button
    :action-items="$options.actionItems"
    class="js-issue-actions-split-button"
    data-qa-selector="issue_actions_split_button"
    menu-class="dropdown-menu-large"
    right
    size="sm"
    v-on="$listeners"
    @change="change"
  />
</template>
