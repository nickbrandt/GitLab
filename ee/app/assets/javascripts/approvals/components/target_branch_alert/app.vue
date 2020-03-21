<script>
import { GlAlert } from '@gitlab/ui';
import { mapState, mapActions } from 'vuex';

export default {
  components: {
    GlAlert,
  },
  computed: {
    ...mapState('targetBranchAlertModule', ['showTargetBranchAlert', 'targetBranch']),
  },
  methods: {
    ...mapActions('targetBranchAlertModule', ['toggleDisplayTargetBranchAlert']),
    ...mapActions(['fetchRules']),
    approveTargetBranchAction() {
      this.toggleDisplayTargetBranchAlert(false);
      return this.fetchRules(this.targetBranch);
    },
  },
};
</script>

<template>
  <div>
    <gl-alert
      v-if="showTargetBranchAlert"
      primary-button-text="Charge target branch"
      secondary-button-text="Cancel"
      variant="warning"
      :dismissible="false"
      @primaryAction="approveTargetBranchAction"
      @secondaryAction="toggleDisplayTargetBranchAlert(false)"
      >{{
        __(
          'Changing target branch will reset the approval rules. Any changes you have made will be lost.',
        )
      }}</gl-alert
    >
  </div>
</template>
