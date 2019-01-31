<script>
import _ from 'underscore';
import { mapActions } from 'vuex';
import { GlButton, GlSkeletonLoading } from '@gitlab/ui';
import SeverityBadge from 'ee/vue_shared/security_reports/components/severity_badge.vue';
import VulnerabilityActionButtons from './vulnerability_action_buttons.vue';
import VulnerabilityIssueLink from './vulnerability_issue_link.vue';

export default {
  name: 'SecurityDashboardTableRow',
  components: {
    SeverityBadge,
    GlButton,
    GlSkeletonLoading,
    VulnerabilityActionButtons,
    VulnerabilityIssueLink,
  },
  props: {
    vulnerability: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    isLoading: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    confidence() {
      return this.vulnerability.confidence || '–';
    },
    severity() {
      return this.vulnerability.severity || ' ';
    },
    projectFullName() {
      const { project } = this.vulnerability;
      return project && project.full_name;
    },
    isDismissed() {
      return Boolean(this.vulnerability.dismissal_feedback);
    },
    hasIssue() {
      return Boolean(this.vulnerability.issue_feedback);
    },
    canDismissVulnerability() {
      const path = this.vulnerability.vulnerability_feedback_dismissal_path;
      return _.isString(path) && !_.isEmpty(path);
    },
    canCreateIssue() {
      const path = this.vulnerability.vulnerability_feedback_issue_path;
      return _.isString(path) && !_.isEmpty(path) && !this.hasIssue;
    },
  },
  methods: {
    ...mapActions('vulnerabilities', ['openModal']),
  },
};
</script>

<template>
  <div class="gl-responsive-table-row vulnerabilities-row p-2" :class="{ dismissed: isDismissed }">
    <div class="table-section section-10">
      <div class="table-mobile-header" role="rowheader">{{ s__('Reports|Severity') }}</div>
      <div class="table-mobile-content"><severity-badge :severity="severity" /></div>
    </div>

    <div class="table-section flex-grow-1">
      <div class="table-mobile-header" role="rowheader">{{ s__('Reports|Vulnerability') }}</div>
      <div class="table-mobile-content vulnerability-info">
        <gl-skeleton-loading v-if="isLoading" class="mt-2 js-skeleton-loader" :lines="2" />
        <template v-else>
          <gl-button
            class="vulnerability-title d-inline"
            variant="blank"
            @click="openModal({ vulnerability })"
            >{{ vulnerability.name }}</gl-button
          >
          <span v-show="isDismissed" class="vertical-align-middle">DISMISSED</span>
          <vulnerability-issue-link
            v-if="hasIssue"
            class="text-nowrap"
            :issue="vulnerability.issue_feedback"
            :project-name="vulnerability.project.name"
          />
          <br />
          <span v-if="projectFullName" class="vulnerability-namespace">
            {{ projectFullName }}
          </span>
        </template>
      </div>
    </div>

    <div class="table-section section-10 ml-md-2">
      <div class="table-mobile-header" role="rowheader">{{ s__('Reports|Confidence') }}</div>
      <div class="table-mobile-content text-capitalize">{{ confidence }}</div>
    </div>

    <div class="table-section section-20">
      <div class="table-mobile-header" role="rowheader">{{ s__('Reports|Actions') }}</div>
      <div class="table-mobile-content action-buttons d-flex justify-content-end">
        <vulnerability-action-buttons
          :vulnerability="vulnerability"
          :can-create-issue="canCreateIssue"
          :can-dismiss-vulnerability="canDismissVulnerability"
          :is-dismissed="isDismissed"
        />
      </div>
    </div>
  </div>
</template>

<style scoped>
@media (min-width: 768px) {
  .vulnerabilities-row:last-child {
    border-bottom: 1px solid transparent;
  }

  .vulnerabilities-row:hover,
  .vulnerabilities-row:focus {
    background: #f6fafd;
    border-bottom: 1px solid #c1daf4;
    border-top: 1px solid #c1daf4;
    margin-top: -1px;
  }

  .vulnerabilities-row .action-buttons {
    opacity: 0;
  }

  .vulnerabilities-row:hover .action-buttons,
  .vulnerabilities-row:focus .action-buttons {
    opacity: 1;
  }
}

.vulnerability-info {
  white-space: normal;
}

.vulnerability-title {
  text-align: inherit;
  white-space: normal;
  line-height: inherit;
}

.vulnerability-namespace {
  color: #707070;
  font-size: 0.8em;
}

.dismissed .table-mobile-content:not(.action-buttons) {
  opacity: 0.5;
}
</style>
