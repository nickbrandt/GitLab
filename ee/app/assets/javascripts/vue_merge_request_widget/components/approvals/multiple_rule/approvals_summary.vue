<script>
import { n__, sprintf } from '~/locale';
import { toNounSeriesText } from '~/lib/utils/grammar';
import UserAvatarList from '~/vue_shared/components/user_avatar/user_avatar_list.vue';
import { APPROVED_MESSAGE } from '../messages';

export default {
  components: {
    UserAvatarList,
  },
  props: {
    approvalsLeft: {
      type: Number,
      required: true,
    },
    rulesLeft: {
      type: Array,
      required: false,
      default: () => [],
    },
    approvers: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  computed: {
    isApproved() {
      return this.approvalsLeft <= 0;
    },
    message() {
      if (this.isApproved) {
        return APPROVED_MESSAGE;
      }

      if (!this.rulesLeft.length) {
        return n__('Requires approval.', 'Requires %d more approvals.', this.approvalsLeft);
      }

      return sprintf(
        n__(
          'Requires approval from %{names}.',
          'Requires %{count} more approvals from %{names}.',
          this.approvalsLeft,
        ),
        {
          names: toNounSeriesText(this.rulesLeft),
          count: this.approvalsLeft,
        },
      );
    },
    hasApprovers() {
      return !!this.approvers.length;
    },
  },
  APPROVED_MESSAGE,
};
</script>

<template>
  <div>
    <strong>{{ message }}</strong>
    <template v-if="hasApprovers">
      <span>{{ s__('mrWidget|Approved by') }}</span>
      <user-avatar-list class="d-inline-block align-middle" :items="approvers" />
    </template>
  </div>
</template>
