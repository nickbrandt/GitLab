<script>
import { GlAvatarLink, GlAvatarLabeled } from '@gitlab/ui';

const AVATAR_SIZE = 48;

export default {
  name: 'MemberInfo',
  components: { GlAvatarLink, GlAvatarLabeled },
  avatarSize: AVATAR_SIZE,
  props: {
    member: {
      type: Object,
      required: true,
    },
    currentUserId: {
      type: Number,
      required: false,
      default: null,
    },
  },
  computed: {
    user() {
      return this.member.user;
    },
    sharedWithGroup() {
      return this.member.sharedWithGroup;
    },
  },
};
</script>

<template>
  <div>
    <!-- User -->
    <template v-if="user">
      <gl-avatar-link
        class="js-user-link"
        :href="user.webUrl"
        :data-user-id="user.id"
        :data-username="user.username"
      >
        <gl-avatar-labeled
          :label="user.name"
          :sub-label="`@${user.username}`"
          :src="user.avatarUrl"
          :alt="user.name"
          :size="$options.avatarSize"
          :entity-name="user.name"
          :entity-id="user.id"
        />
      </gl-avatar-link>
      <!-- <div  class="gl-mt-n1" style="padding-left: 56px;"></div> -->
    </template>

    <!-- Group  -->
    <gl-avatar-link v-else-if="sharedWithGroup" :href="sharedWithGroup.webUrl">
      <gl-avatar-labeled
        :label="sharedWithGroup.name"
        :src="sharedWithGroup.avatarUrl"
        :alt="sharedWithGroup.name"
        :size="$options.avatarSize"
        :entity-name="sharedWithGroup.name"
        :entity-id="sharedWithGroup.id"
      />
    </gl-avatar-link>

    <!-- Invited User -->
    <gl-avatar-labeled
      v-else
      :label="member.invite.email"
      :src="member.invite.avatarUrl"
      :alt="member.invite.email"
      :size="$options.avatarSize"
      :entity-name="member.invite.email"
    />
  </div>
</template>
