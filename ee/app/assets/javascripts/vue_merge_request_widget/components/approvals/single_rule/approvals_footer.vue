<script>
import Flash from '~/flash';
import Icon from '~/vue_shared/components/icon.vue';
import UserAvatarLink from '~/vue_shared/components/user_avatar/user_avatar_link.vue';

import { s__ } from '~/locale';
import eventHub from '~/vue_merge_request_widget/event_hub';

export default {
  name: 'ApprovalsFooter',
  components: {
    Icon,
    UserAvatarLink,
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
    approvedBy: {
      type: Array,
      required: false,
      default: () => [],
    },
    approvalsLeft: {
      type: Number,
      required: false,
      default: 0,
    },
    userCanApprove: {
      type: Boolean,
      required: false,
      default: false,
    },
    userHasApproved: {
      type: Boolean,
      required: false,
      default: false,
    },
    suggestedApprovers: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  data() {
    return {
      unapproving: false,
    };
  },
  computed: {
    showUnapproveButton() {
      const isMerged = this.mr.state === 'merged';
      return this.userHasApproved && !this.userCanApprove && !isMerged;
    },
    approvedByText() {
      return s__('mrWidget|Approved by');
    },
    removeApprovalText() {
      return s__('mrWidget|Remove your approval');
    },
  },
  methods: {
    unapproveMergeRequest() {
      this.unapproving = true;
      this.service
        .unapproveMergeRequest()
        .then(data => {
          this.mr.setApprovals(data);
          eventHub.$emit('MRWidgetUpdateRequested');
          this.unapproving = false;
        })
        .catch(() => {
          this.unapproving = false;
          Flash(s__('mrWidget|An error occurred while removing your approval.'));
        });
    },
  },
};
</script>
<template>
  <div v-if="approvedBy.length" class="approved-by-users approvals-footer clearfix mr-info-list">
    <div class="approvers-prefix">
      <p>{{ approvedByText }}</p>
      <div class="approvers-list">
        <user-avatar-link
          v-for="approver in approvedBy"
          :key="approver.user.username"
          class="js-approver-list-member"
          :img-size="20"
          :img-src="approver.user.avatar_url"
          :img-alt="approver.user.name"
          :link-href="approver.user.web_url"
          :tooltip-text="approver.user.name"
          tooltip-placement="bottom"
        />
        <icon
          v-for="n in approvalsLeft"
          :key="n"
          name="dotted-circle"
          class="avatar avatar-placeholder s20"
        />
      </div>
      <button
        v-if="showUnapproveButton"
        :disabled="unapproving"
        type="button"
        class="btn btn-sm unapprove-btn-wrap"
        @click="unapproveMergeRequest"
      >
        <i v-if="unapproving" class="fa fa-spinner fa-spin" aria-hidden="true"> </i>
        {{ removeApprovalText }}
      </button>
    </div>
  </div>
</template>
