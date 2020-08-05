<script>
import eventHub from '~/boards/eventhub';
import BoardCard from '~/boards/components/board_card.vue';
import BoardNewIssue from '~/boards/components/board_new_issue.vue';

export default {
  components: {
    BoardCard,
    BoardNewIssue,
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
    groupId: {
      type: Number,
      required: false,
      default: 0,
    },
    isUnassignedIssuesLane: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      showIssueForm: false,
    };
  },
  created() {
    eventHub.$on(`toggle-issue-form-${this.list.id}`, this.toggleForm);
  },
  beforeDestroy() {
    eventHub.$off(`toggle-issue-form-${this.list.id}`, this.toggleForm);
  },
  methods: {
    toggleForm() {
      this.showIssueForm = !this.showIssueForm;
      if (this.showIssueForm && this.isUnassignedIssuesLane) {
        this.$el.scrollIntoView(false);
      }
    },
  },
};
</script>

<template>
  <div
    class="board gl-px-3 gl-vertical-align-top gl-white-space-normal gl-display-flex gl-flex-shrink-0"
    :class="{ 'is-collapsed': !list.isExpanded }"
  >
    <div class="board-inner gl-rounded-base gl-relative gl-w-full">
      <board-new-issue
        v-if="list.type !== 'closed' && showIssueForm && isUnassignedIssuesLane"
        :group-id="groupId"
        :list="list"
      />
      <ul v-if="list.isExpanded" class="gl-p-2 gl-m-0">
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
