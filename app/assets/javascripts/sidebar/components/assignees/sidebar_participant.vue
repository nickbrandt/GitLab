<script>
import { GlAvatarLabeled, GlAvatarLink, GlIcon } from '@gitlab/ui';
import { IssuableType } from '~/issue_show/constants';
import { s__, sprintf } from '~/locale';

export default {
  components: {
    GlAvatarLabeled,
    GlAvatarLink,
    GlIcon,
  },
  props: {
    user: {
      type: Object,
      required: true,
    },
    issuableType: {
      type: String,
      required: false,
      default: 'issue',
    },
  },
  computed: {
    userLabel() {
      if (!this.user.status) {
        return this.user.name;
      }
      return sprintf(s__('UserAvailability|%{author} (Busy)'), {
        author: this.user.name,
      });
    },
    hasMergeIcon() {
      return (
        this.issuableType === IssuableType.MergeRequest &&
        !this.user.mergeRequestInteraction?.canMerge
      );
    },
  },
};
</script>

<template>
  <gl-avatar-link>
    <gl-avatar-labeled
      :size="32"
      :label="userLabel"
      :sub-label="user.username"
      :src="user.avatarUrl || user.avatar || user.avatar_url"
      class="gl-align-items-center"
    />
    <gl-icon
      v-if="hasMergeIcon"
      name="warning-solid"
      aria-hidden="true"
      class="merge-icon"
      :size="12"
    />
  </gl-avatar-link>
</template>
