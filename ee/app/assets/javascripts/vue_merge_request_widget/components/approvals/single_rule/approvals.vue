<script>
import createFlash from '~/flash';
import MrWidgetContainer from '~/vue_merge_request_widget/components/mr_widget_container.vue';
import MrWidgetIcon from '~/vue_merge_request_widget/components/mr_widget_icon.vue';
import ApprovalsBody from './approvals_body.vue';
import ApprovalsFooter from './approvals_footer.vue';
import { FETCH_LOADING, FETCH_ERROR } from '../messages';

export default {
  name: 'MRWidgetSingleRuleApprovals',
  components: {
    ApprovalsBody,
    ApprovalsFooter,
    MrWidgetContainer,
    MrWidgetIcon,
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
    };
  },

  computed: {
    status() {
      if (this.mr.approvals.approvals_left > 0) {
        return 'warning';
      }
      return 'success';
    },
    approvalsOptional() {
      return (
        !this.fetchingApprovals &&
        this.mr.approvals.approvals_required === 0 &&
        this.mr.approvals.approved_by.length === 0
      );
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
  FETCH_LOADING,
};
</script>
<template>
  <mr-widget-container>
    <div v-if="mr.approvalsRequired" class="media media-section js-mr-approvals align-items-center">
      <mr-widget-icon name="approval" />
      <div v-show="fetchingApprovals" class="mr-approvals-loading-state media-body">
        <span class="approvals-loading-text"> {{ $options.FETCH_LOADING }} </span>
      </div>
      <div v-if="!fetchingApprovals" class="approvals-components media-body">
        <approvals-body
          :mr="mr"
          :service="service"
          :user-can-approve="mr.approvals.user_can_approve"
          :user-has-approved="mr.approvals.user_has_approved"
          :approved-by="mr.approvals.approved_by"
          :approvals-left="mr.approvals.approvals_left"
          :approvals-optional="approvalsOptional"
          :suggested-approvers="mr.approvals.suggested_approvers"
        />
        <approvals-footer
          :mr="mr"
          :service="service"
          :user-can-approve="mr.approvals.user_can_approve"
          :user-has-approved="mr.approvals.user_has_approved"
          :approved-by="mr.approvals.approved_by"
          :approvals-left="mr.approvals.approvals_left"
        />
      </div>
    </div>
  </mr-widget-container>
</template>
