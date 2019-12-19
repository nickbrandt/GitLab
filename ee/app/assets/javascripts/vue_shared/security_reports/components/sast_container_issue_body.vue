<script>
/**
 * Renders SAST CONTAINER body text
 * [priority]: [name] in [link]:[line]
 */
import ModalOpenName from '~/reports/components/modal_open_name.vue';
import { humanize } from '~/lib/utils/text_utility';

export default {
  name: 'SastContainerIssueBody',
  components: {
    ModalOpenName,
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
  computed: {
    severity() {
      return this.issue.severity ? humanize(this.issue.severity) : null;
    },
  },
};
</script>
<template>
  <div class="report-block-list-issue-description prepend-top-5 append-bottom-5">
    <div class="report-block-list-issue-description-text">
      <template v-if="severity">
        {{ severity }}:
      </template>

      <modal-open-name :issue="issue" :status="status" />
    </div>
  </div>
</template>
