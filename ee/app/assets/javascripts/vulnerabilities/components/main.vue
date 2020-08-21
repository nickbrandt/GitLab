<script>
import Vue from 'vue';
import VulnerabilityHeader from './header.vue';
import VulnerabilityDetails from './details.vue';
import VulnerabilityFooter from './footer.vue';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { VULNERABILITY_STATE_OBJECTS } from 'ee/vulnerabilities/constants';

export default {
  name: 'Vulnerability',

  components: { VulnerabilityHeader, VulnerabilityDetails, VulnerabilityFooter },

  props: {
    vulnerability: {
      type: Object,
      required: true,
    },
  },

  computed: {
    footerInfo: function() {
      const {
        vulnerabilityFeedbackHelpPath,
        hasMr,
        discussionsUrl,
        createIssueUrl,
        state,
        issueFeedback,
        mergeRequestFeedback,
        notesUrl,
        project,
        projectFingerprint,
        remediations,
        reportType,
        solution,
        id,
        canModifyRelatedIssues,
        relatedIssuesHelpPath,
      } = convertObjectPropsToCamelCase(this.vulnerability);

      const remediation = remediations?.length ? remediations[0] : null;
      const hasDownload = Boolean(
        state !== VULNERABILITY_STATE_OBJECTS.resolved.state && remediation?.diff?.length && !hasMr,
      );
      const hasRemediation = Boolean(remediation);

      const props = {
        vulnerabilityId: id,
        discussionsUrl,
        notesUrl,
        projectFingerprint,
        solutionInfo: {
          solution,
          remediation,
          hasDownload,
          hasMr,
          hasRemediation,
          vulnerabilityFeedbackHelpPath,
          isStandaloneVulnerability: true,
        },
        createIssueUrl,
        reportType,
        issueFeedback,
        mergeRequestFeedback,
        canModifyRelatedIssues,
        project: {
          url: this.vulnerability.project.full_path,
          value: this.vulnerability.project.full_name,
        },
        relatedIssuesHelpPath,
      };

      return props;
    },
  },

  methods: {
    handleVulnerabilityStateChange(a) {
      console.error('state-change', this.footerInfo);
      this.$refs.footer.fetchDiscussions();
    },
  },
};
</script>

<template>
  <div>
    <vulnerability-header
      :initialVulnerability="vulnerability"
      v-on:vulnerability-state-change="handleVulnerabilityStateChange"
    ></vulnerability-header>
    <vulnerability-details :vulnerability="vulnerability"></vulnerability-details>
    <vulnerability-footer
      v-bind="footerInfo"
      v-on:vulnerability-state-change="handleVulnerabilityStateChange"
      ref="footer"
    ></vulnerability-footer>
  </div>
</template>