<script>
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';

export default {
  name: 'GroupMembersApp',
  props: {
    groupId: {
      type: Number,
      required: true,
    },
    currentUserId: {
      type: Number,
      required: false,
      default: null,
    },
    members: {
      type: Array,
      required: true,
    },
  },
  computed: {
    formattedMembers() {
      return convertObjectPropsToCamelCase(this.members, { deep: true });
    },
  },
};
</script>

<template>
  <span>
    <!-- Temporary empty template -->
  </span>
</template>
