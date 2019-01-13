<script>
import createFlash from '~/flash';
import MrWidgetContainer from '~/vue_merge_request_widget/components/mr_widget_container.vue';
import MrWidgetIcon from '~/vue_merge_request_widget/components/mr_widget_icon.vue';
import { FETCH_LOADING, FETCH_ERROR } from '../messages';

export default {
  name: 'MRWidgetMultipleRuleApprovals',
  components: {
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
    canApprove() {
      return this.mr.isOpen;
    },
    canUnapprove() {
      return this.mr.state !== 'merged';
    },
    action() {
      if (!this.mr.userCanApprove) {
        return null;
      } else if (this.mr.userHasApproved && this.canUnapprove) {
        return {
          text: s__('mrWidget|Revoke approval'),
          variant: 'warning',
          inverted: true,
          action: () => {},
        };
      } else if (!this.mr.userHasApproved && this.canApprove) {
        if (this.mr.approvals.approved) {
          return {
            text: s__('mrWidget|Approve additionally'),
            variant: 'primary',
            inverted: true,
            action: () => {},
          };
        }

        return {
          text: s__('mrWidget|Approve'),
          variant: 'primary',
          action: () => {},
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
  FETCH_LOADING,
};
</script>

<template>
  <mr-widget-container>
    <div class="js-mr-approvals d-flex align-items-center">
      <mr-widget-icon name="approval" />
      <div v-if="fetchingApprovals" class="media-body">
        <span class="approvals-loading-text"> {{ $options.FETCH_LOADING }} </span>
      </div>
    </div>
  </mr-widget-container>
</template>
