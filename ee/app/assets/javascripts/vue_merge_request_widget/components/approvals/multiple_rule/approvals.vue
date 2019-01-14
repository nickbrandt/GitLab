<script>
import { GlButton, GlLoadingIcon } from '@gitlab/ui';
import createFlash from '~/flash';
import { s__ } from '~/locale';
import UserAvatarList from '~/vue_shared/components/user_avatar/user_avatar_list.vue';
import eventHub from '~/vue_merge_request_widget/event_hub';
import MrWidgetContainer from '~/vue_merge_request_widget/components/mr_widget_container.vue';
import MrWidgetIcon from '~/vue_merge_request_widget/components/mr_widget_icon.vue';
import ApprovalsSummary from './approvals_summary.vue';
import { FETCH_LOADING, FETCH_ERROR, APPROVE_ERROR, UNAPPROVE_ERROR } from '../messages';

export default {
  name: 'MRWidgetMultipleRuleApprovals',
  components: {
    UserAvatarList,
    MrWidgetContainer,
    MrWidgetIcon,
    ApprovalsSummary,
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
    };
  },
  computed: {
    approvedBy() {
      return this.mr.approvals.approved_by.map(x => x.user);
    },
    userHasApproved() {
      return this.mr.approvals.user_has_approved;
    },
    userCanApprove() {
      return this.mr.approvals.user_can_approve;
    },
    showApprove() {
      return !this.userHasApproved && this.userCanApprove && this.mr.isOpen;
    },
    showUnapprove() {
      return this.userHasApproved && !this.userCanApprove && this.mr.state !== 'merged';
    },
    action() {
      if (this.showApprove && this.mr.approvals.approved) {
        return {
          text: s__('mrWidget|Approve additionally'),
          variant: 'primary',
          inverted: true,
          action: () => this.approve(),
        };
      } else if (this.showApprove) {
        return {
          text: s__('mrWidget|Approve'),
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
  },
  created() {
    this.service
      .fetchApprovals()
      .then(data => {
        this.mr.setApprovals(data);
        this.fetchingApprovals = false;
      })
      .catch(() => createFlash(FETCH_ERROR));
  },
  methods: {
    approve() {
      this.onApprovalRequest();
      this.service
        .approveMergeRequest()
        .then(data => this.onApprovalSuccess(data))
        .catch(() => this.onApprovalError(APPROVE_ERROR));
    },
    unapprove() {
      this.onApprovalRequest();
      this.service
        .unapproveMergeRequest()
        .then(data => this.onApprovalSuccess(data))
        .catch(() => this.onApprovalError(UNAPPROVE_ERROR));
    },
    onApprovalRequest() {
      this.isApproving = true;
    },
    onApprovalSuccess(data) {
      this.mr.setApprovals(data);
      eventHub.$emit('MRWidgetUpdateRequested');
      this.isApproving = false;
    },
    onApprovalError(msg) {
      createFlash(msg);
      this.isApproving = false;
    },
  },
  FETCH_LOADING,
};
</script>

<template>
  <mr-widget-container>
    <div class="js-mr-approvals d-flex align-items-center">
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
        <approvals-summary
          :approvals-left="mr.approvals.approvals_left"
          :rules-left="mr.approvals.approval_rules_left"
          :approvers="approvedBy"
        />
      </template>
    </div>
  </mr-widget-container>
</template>
