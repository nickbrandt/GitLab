/* global Flash */

import ApprovalsBody from './approvals_body';
import ApprovalsFooter from './approvals_footer';

export default {
  name: 'MRWidgetApprovals',
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
  components: {
    'approvals-body': ApprovalsBody,
    'approvals-footer': ApprovalsFooter,
  },
  template: `
    <div
      v-if="mr.approvalsRequired"
      class="mr-widget-approvals-container mr-widget-body">
      <div
        class="approvals-components">
        <approvals-body
          :mr="mr"
          :service="service"
          :user-can-approve="mr.approvals.user_can_approve"
          :user-has-approved="mr.approvals.user_has_approved"
          :approved-by="mr.approvals.approved_by"
          :approvals-left="mr.approvals.approvals_left"
          :suggested-approvers="mr.approvals.suggested_approvers" />
        <approvals-footer
          :mr="mr"
          :service="service"
          :user-can-approve="mr.approvals.user_can_approve"
          :user-has-approved="mr.approvals.user_has_approved"
          :approved-by="mr.approvals.approved_by"
          :approvals-left="mr.approvals.approvals_left" />
      </div>
    </div>
    `,
};
