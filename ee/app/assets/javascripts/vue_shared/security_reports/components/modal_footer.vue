<script>
import { GlButton } from '@gitlab/ui';
import { s__ } from '~/locale';
import DismissButton from 'ee/vue_shared/security_reports/components/dismiss_button.vue';
import LoadingButton from '~/vue_shared/components/loading_button.vue';
import SplitButton from 'ee/vue_shared/security_reports/components/split_button.vue';

export default {
  name: 'ModalFooter',
  components: {
    DismissButton,
    GlButton,
    LoadingButton,
    SplitButton,
  },
  props: {
    modal: {
      type: Object,
      required: true,
    },
    isDismissed: {
      type: Boolean,
      required: false,
      default: false,
    },
    canCreateIssue: {
      type: Boolean,
      required: false,
      default: false,
    },
    canCreateMergeRequest: {
      type: Boolean,
      required: false,
      default: false,
    },
    canDismissVulnerability: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    actionButtons() {
      const buttons = [];
      const issueButton = {
        name: s__('ciReport|Create issue'),
        tagline: s__('ciReport|Investigate this vulnerability by creating an issue'),
        isLoading: this.modal.isCreatingNewIssue,
        action: 'createNewIssue',
      };
      const MRButton = {
        name: s__('ciReport|Create merge request'),
        tagline: s__('ciReport|Implement this solution by creating a merge request'),
        isLoading: this.modal.isCreatingMergeRequest,
        action: 'createMergeRequest',
      };

      if (this.canCreateMergeRequest) {
        buttons.push(MRButton);
      }

      if (this.canCreateIssue) {
        buttons.push(issueButton);
      }

      return buttons;
    },
  },
};
</script>

<template>
  <div>
    <gl-button data-dismiss="modal">
      {{ __('Cancel') }}
    </gl-button>

    <dismiss-button
      v-if="canDismissVulnerability"
      :is-dismissing="modal.isDismissingIssue"
      :is-dismissed="isDismissed"
      @dismissVulnerability="$emit('dismissVulnerability')"
      @openDismissalCommentBox="$emit('openDismissalCommentBox')"
      @revertDismissVulnerability="$emit('revertDismissVulnerability')"
    />

    <split-button
      v-if="actionButtons.length > 1"
      :buttons="actionButtons"
      @createMergeRequest="$emit('createMergeRequest')"
      @createNewIssue="$emit('createNewIssue')"
    />

    <loading-button
      v-else-if="actionButtons.length > 0"
      :loading="actionButtons[0].isLoading"
      :disabled="actionButtons[0].isLoading"
      :label="actionButtons[0].name"
      container-class="btn btn-success btn-inverted"
      @click="$emit(actionButtons[0].action)"
    />
  </div>
</template>
