<script>
import { GlButton, GlLoadingIcon } from '@gitlab/ui';
import createFlash from '~/flash';
import { s__ } from '~/locale';
import UserAvatarList from '~/vue_shared/components/user_avatar/user_avatar_list.vue';
import eventHub from '~/vue_merge_request_widget/event_hub';
import MrWidgetContainer from '~/vue_merge_request_widget/components/mr_widget_container.vue';
import MrWidgetIcon from '~/vue_merge_request_widget/components/mr_widget_icon.vue';
import ApprovalsSummary from './approvals_summary.vue';
import ApprovalsSummaryOptional from './approvals_summary_optional.vue';
import ApprovalsFooter from './approvals_footer.vue';
import { FETCH_LOADING, FETCH_ERROR, APPROVE_ERROR, UNAPPROVE_ERROR } from '../messages';

export default {
  name: 'MRWidgetMultipleRuleApprovals',
  components: {
    UserAvatarList,
    MrWidgetContainer,
    MrWidgetIcon,
    ApprovalsSummary,
    ApprovalsSummaryOptional,
    ApprovalsFooter,
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
    };
  },
  computed: {
    approvals() {
      return this.mr.approvals || {};
    },
    hasFooter() {
      return !!this.approvals.has_approval_rules;
    },
    approvedBy() {
      return this.approvals.approved_by ? this.approvals.approved_by.map(x => x.user) : [];
    },
    isApproved() {
      return !!this.approvals.approved;
    },
    approvalsRequired() {
      return this.approvals.approvals_required || 0;
    },
    isOptional() {
      return !this.approvedBy.length && !this.approvalsRequired;
    },
    userHasApproved() {
      return !!this.approvals.user_has_approved;
    },
    userCanApprove() {
      return !!this.approvals.user_can_approve;
    },
    showApprove() {
      return !this.userHasApproved && this.userCanApprove && this.mr.isOpen;
    },
    showUnapprove() {
      return this.userHasApproved && !this.userCanApprove && this.mr.state !== 'merged';
    },
    action() {
      if (this.showApprove) {
        const inverted = this.isApproved;
        const text =
          this.isApproved && this.approvedBy.length > 0
            ? s__('mrWidget|Approve additionally')
            : s__('mrWidget|Approve');

        return {
          text,
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
      return !!this.action;
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
      this.updateApproval(() => this.service.approveMergeRequest(), APPROVE_ERROR);
    },
    unapprove() {
      this.updateApproval(() => this.service.unapproveMergeRequest(), UNAPPROVE_ERROR);
    },
    updateApproval(serviceFn, error) {
      this.isApproving = true;

      return serviceFn()
        .then(data => {
          this.mr.setApprovals(data);
          eventHub.$emit('MRWidgetUpdateRequested');
          this.isApproving = false;
        })
        .catch(() => {
          createFlash(error);
          this.isApproving = false;
        })
        .then(() => this.refreshRules());
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
        <gl-button
          v-if="action"
          :variant="action.variant"
          :class="{ 'btn-inverted': action.inverted }"
          size="sm"
          class="mr-3"
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
    />
  </mr-widget-container>
</template>
