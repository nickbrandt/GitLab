<script>
import { GlButton, GlLoadingIcon } from '@gitlab/ui';
import createFlash, { hideFlash } from '~/flash';
import { s__ } from '~/locale';
import eventHub from '~/vue_merge_request_widget/event_hub';
import MrWidgetContainer from '~/vue_merge_request_widget/components/mr_widget_container.vue';
import MrWidgetIcon from '~/vue_merge_request_widget/components/mr_widget_icon.vue';
import ApprovalsSummary from './approvals_summary.vue';
import ApprovalsSummaryOptional from './approvals_summary_optional.vue';
import ApprovalsFooter from './approvals_footer.vue';
import ApprovalsAuth from './approvals_auth.vue';
import { FETCH_LOADING, FETCH_ERROR, APPROVE_ERROR, UNAPPROVE_ERROR } from './messages';

export default {
  name: 'MRWidgetMultipleRuleApprovals',
  components: {
    MrWidgetContainer,
    MrWidgetIcon,
    ApprovalsSummary,
    ApprovalsSummaryOptional,
    ApprovalsFooter,
    ApprovalsAuth,
    GlButton,
    GlLoadingIcon,
  },
  props: {
    mr: {
      type: Object,
      required: true,
    },
    service: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      fetchingApprovals: true,
      isApproving: false,
      isExpanded: false,
      isLoadingRules: false,
      hasApprovalAuthError: false,
      modalId: 'approvals-auth',
    };
  },
  computed: {
    approvals() {
      return this.mr.approvals || {};
    },
    hasFooter() {
      return Boolean(this.mr.approvals);
    },
    approvedBy() {
      return this.approvals.approved_by ? this.approvals.approved_by.map(x => x.user) : [];
    },
    isApproved() {
      return Boolean(this.approvals.approved);
    },
    approvalsRequired() {
      return this.approvals.approvals_required || 0;
    },
    isOptional() {
      return !this.approvedBy.length && !this.approvalsRequired;
    },
    userHasApproved() {
      return Boolean(this.approvals.user_has_approved);
    },
    userCanApprove() {
      return Boolean(this.approvals.user_can_approve);
    },
    showApprove() {
      return !this.userHasApproved && this.userCanApprove && this.mr.isOpen;
    },
    showUnapprove() {
      return this.userHasApproved && !this.userCanApprove && this.mr.state !== 'merged';
    },
    requirePasswordToApprove() {
      return this.mr.approvals.require_password_to_approve;
    },
    approvalText() {
      return this.isApproved && this.approvedBy.length > 0
        ? s__('mrWidget|Approve additionally')
        : s__('mrWidget|Approve');
    },
    action() {
      // Use the default approve action, only if we aren't using the auth component for it
      if (this.showApprove) {
        const inverted = this.isApproved;
        return {
          text: this.approvalText,
          inverted,
          variant: 'primary',
          action: () => this.approve(),
        };
      } else if (this.showUnapprove) {
        return {
          text: s__('mrWidget|Revoke approval'),
          variant: 'warning',
          inverted: true,
          action: () => this.unapprove(),
        };
      }

      return null;
    },
    hasAction() {
      return Boolean(this.action);
    },
  },
  watch: {
    isExpanded(val) {
      if (val) {
        this.refreshAll();
      }
    },
  },
  created() {
    this.refreshApprovals()
      .then(() => {
        this.fetchingApprovals = false;
      })
      .catch(() => createFlash(FETCH_ERROR));
  },
  methods: {
    clearError() {
      this.hasApprovalAuthError = false;
      const flashEl = document.querySelector('.flash-alert');
      if (flashEl) {
        hideFlash(flashEl);
      }
    },
    refreshAll() {
      return Promise.all([this.refreshRules(), this.refreshApprovals()]).catch(() =>
        createFlash(FETCH_ERROR),
      );
    },
    refreshRules() {
      this.isLoadingRules = true;

      return this.service.fetchApprovalSettings().then(settings => {
        this.mr.setApprovalRules(settings);
        this.isLoadingRules = false;
      });
    },
    refreshApprovals() {
      return this.service.fetchApprovals().then(data => {
        this.mr.setApprovals(data);
      });
    },
    approve() {
      if (this.requirePasswordToApprove) {
        this.$root.$emit('bv::show::modal', this.modalId);
        return;
      }
      this.updateApproval(
        () => this.service.approveMergeRequest(),
        () => createFlash(APPROVE_ERROR),
      );
    },
    unapprove() {
      this.updateApproval(
        () => this.service.unapproveMergeRequest(),
        () => createFlash(UNAPPROVE_ERROR),
      );
    },
    approveWithAuth(data) {
      this.updateApproval(
        () => this.service.approveMergeRequestWithAuth(data),
        error => {
          if (error && error.response && error.response.status === 401) {
            this.hasApprovalAuthError = true;
            return;
          }
          createFlash(APPROVE_ERROR);
        },
      );
    },
    updateApproval(serviceFn, errFn) {
      this.isApproving = true;
      this.clearError();
      return serviceFn()
        .then(data => {
          this.mr.setApprovals(data);
          eventHub.$emit('MRWidgetUpdateRequested');
          this.$root.$emit('bv::hide::modal', this.modalId);
        })
        .catch(errFn)
        .then(() => {
          this.isApproving = false;
          this.refreshRules();
        });
    },
  },
  FETCH_LOADING,
};
</script>
<template>
  <mr-widget-container>
    <div class="js-mr-approvals d-flex align-items-start align-items-md-center">
      <mr-widget-icon name="approval" />
      <div v-if="fetchingApprovals">{{ $options.FETCH_LOADING }}</div>
      <template v-else>
        <approvals-auth
          :is-approving="isApproving"
          :has-error="hasApprovalAuthError"
          :modal-id="modalId"
          @approve="approveWithAuth"
          @hide="clearError"
        />
        <gl-button
          v-if="action"
          :variant="action.variant"
          :class="{ 'btn-inverted': action.inverted }"
          size="sm"
          class="mr-3"
          data-qa-selector="approve_button"
          @click="action.action"
        >
          <gl-loading-icon v-if="isApproving" inline />
          {{ action.text }}
        </gl-button>
        <approvals-summary-optional
          v-if="isOptional"
          :can-approve="hasAction"
          :help-path="mr.approvalsHelpPath"
        />
        <approvals-summary
          v-else
          :approved="isApproved"
          :approvals-left="approvals.approvals_left"
          :rules-left="approvals.approvalRuleNamesLeft"
          :approvers="approvedBy"
        />
      </template>
    </div>
    <approvals-footer
      v-if="hasFooter"
      slot="footer"
      v-model="isExpanded"
      :suggested-approvers="approvals.suggested_approvers"
      :approval-rules="mr.approvalRules"
      :is-loading-rules="isLoadingRules"
      :security-approvals-help-page-path="mr.securityApprovalsHelpPagePath"
      :eligible-approvers-docs-path="mr.eligibleApproversDocsPath"
    />
  </mr-widget-container>
</template>
