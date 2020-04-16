<script>
/**
 * Renders SECRET SCANNING body text
 * [severity-badge] [name] in [link]:[line]
 */
import ModalOpenName from '~/reports/components/modal_open_name.vue';
import SeverityBadge from './severity_badge.vue';

export default {
  name: 'SecretScanningIssueBody',
  components: {
    ModalOpenName,
    SeverityBadge,
  },
  props: {
    issue: {
      type: Object,
      required: true,
    },
    // failed || success
    status: {
      type: String,
      required: true,
    },
  },
};
</script>
<template>
  <div class="report-block-list-issue-description prepend-top-5 append-bottom-5">
    <div class="report-block-list-issue-description-text">
      <severity-badge v-if="issue.severity" class="d-inline-block" :severity="issue.severity" />
      <modal-open-name :issue="issue" :status="status" />
    </div>
  </div>
</template>
