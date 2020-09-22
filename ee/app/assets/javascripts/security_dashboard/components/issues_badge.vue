<script>
import { GlIcon, GlPopover, GlBadge } from '@gitlab/ui';
import IssueLink from 'ee/vulnerabilities/components/issue_link.vue';

export default {
  components: {
    GlIcon,
    GlBadge,
    GlPopover,
    IssueLink,
  },
  props: {
    issues: {
      type: Array,
      required: true,
    },
  },
  computed: {
    numberOfIssues() {
      return this.issues.length;
    },
  },
};
</script>

<template>
  <div class="gl-display-inline-block">
    <gl-badge ref="issueBadge" class="gl-px-3">
      <gl-icon name="issues" class="gl-mr-2" />
      {{ numberOfIssues }}
    </gl-badge>
    <gl-popover ref="popover" :target="() => $refs.issueBadge.$el" triggers="hover" placement="top">
      <template #title>
        {{ n__('1 Issue', '%d Issues', numberOfIssues) }}
      </template>
      <div v-for="{ issue } in issues" :key="issue.iid">
        <issue-link :issue="issue" />
      </div>
    </gl-popover>
  </div>
</template>
