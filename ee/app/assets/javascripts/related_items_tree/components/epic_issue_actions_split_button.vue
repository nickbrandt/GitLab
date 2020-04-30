<script>
import { GlDropdown, GlDropdownDivider, GlDropdownHeader, GlDropdownItem } from '@gitlab/ui';

import { s__ } from '~/locale';

const epicActionItems = [
  {
    title: s__('Epics|Add an epic'),
    description: s__('Epics|Add an existing epic as a child epic.'),
    eventName: 'showAddEpicForm',
  },
  {
    title: s__('Epics|Create new epic'),
    description: s__('Epics|Create an epic within this group and add it as a child epic.'),
    eventName: 'showCreateEpicForm',
  },
];

const issueActionItems = [
  {
    title: s__('Add an issue'),
    description: s__('Add an existing issue to the epic.'),
    eventName: 'showAddIssueForm',
  },
  {
    title: s__('Create an issue'),
    description: s__('Create a new issue and add it to the epic.'),
    eventName: 'showCreateIssueForm',
  },
];

export default {
  epicActionItems,
  issueActionItems,
  components: {
    GlDropdown,
    GlDropdownDivider,
    GlDropdownHeader,
    GlDropdownItem,
  },
  props: {
    allowSubEpics: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    actionItems() {
      return this.allowSubEpics ? [...epicActionItems, ...issueActionItems] : issueActionItems;
    },
  },
  methods: {
    change(item) {
      this.$emit(item.eventName);
    },
  },
};
</script>

<template>
  <gl-dropdown
    :menu-class="`dropdown-menu-selectable`"
    :text="s__('Add')"
    variant="secondary"
    data-qa-selector="epic_issue_actions_split_button"
    v-on="$listeners"
  >
    <gl-dropdown-header>{{ s__('Issue') }}</gl-dropdown-header>
    <template v-for="item in $options.issueActionItems">
      <gl-dropdown-item :key="item.eventName" active-class="is-active" @click="change(item)">
        {{ item.title }}
      </gl-dropdown-item>
    </template>
    <template v-if="allowSubEpics">
      <gl-dropdown-divider />
      <gl-dropdown-header>{{ s__('Epic') }}</gl-dropdown-header>
      <template v-for="item in $options.epicActionItems">
        <gl-dropdown-item :key="item.eventName" active-class="is-active" @click="change(item)">
          {{ item.title }}
        </gl-dropdown-item>
      </template>
    </template>
  </gl-dropdown>
</template>
