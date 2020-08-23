<script>
import { VULNERABILITY_STATE_OBJECTS } from 'ee/vulnerabilities/constants';
import VulnerabilityHeader from './header.vue';
import VulnerabilityDetails from './details.vue';
import VulnerabilityFooter from './footer.vue';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';

export default {
  // eslint-disable-next-line @gitlab/require-i18n-strings
  name: 'Vulnerability',

  components: { VulnerabilityHeader, VulnerabilityDetails, VulnerabilityFooter },

  props: {
    vulnerability: {
      type: Object,
      required: true,
    },
  },

  computed: {
    footerInfo() {
      const {
        vulnerabilityFeedbackHelpPath,
        hasMr,
        discussionsUrl,
        createIssueUrl,
        state,
        issueFeedback,
        mergeRequestFeedback,
        notesUrl,
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
    handleVulnerabilityStateChange(newState) {
      if (newState) {
        this.$refs.footer.fetchDiscussions();
      } else {
        this.$refs.header.refreshVulnerability();
      }
    },
  },
};
</script>

<template>
  <div>
    <vulnerability-header
      ref="header"
      :initial-vulnerability="vulnerability"
      @vulnerability-state-change="handleVulnerabilityStateChange"
    />
    <vulnerability-details :vulnerability="vulnerability" />
    <vulnerability-footer
      ref="footer"
      v-bind="footerInfo"
      @vulnerability-state-change="handleVulnerabilityStateChange"
    />
  </div>
</template>
