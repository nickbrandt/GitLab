<script>
import SplitButton from '~/vue_shared/components/split_button.vue';

import { s__ } from '~/locale';

const actionItems = [
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
    class="js-add-epics-button"
    menu-class="dropdown-menu-large"
    right
    size="sm"
    v-on="$listeners"
    @change="change"
  />
</template>
