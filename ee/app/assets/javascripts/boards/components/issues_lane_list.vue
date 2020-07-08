<script>
import BoardCard from '~/boards/components/board_card.vue';

export default {
  components: {
    BoardCard,
  },
  props: {
    list: {
      type: Object,
      required: true,
    },
    issues: {
      type: Array,
      required: true,
    },
  },
};
</script>

<template>
  <div
    class="board gl-px-3 gl-vertical-align-top gl-white-space-normal gl-display-flex gl-flex-shrink-0 is-expandable"
    :class="{ 'is-collapsed': !list.isExpanded }"
  >
    <div class="board-inner gl-p-2 gl-rounded-base gl-relative gl-w-full">
      <ul v-if="list.isExpanded" class="gl-p-0 gl-m-0">
        <board-card
          v-for="(issue, index) in issues"
          ref="issue"
          :key="issue.id"
          :index="index"
          :list="list"
          :issue="issue"
        />
      </ul>
    </div>
  </div>
</template>
