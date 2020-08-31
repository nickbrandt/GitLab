<script>
import MembersList from '~/vue_shared/components/members/members_list.vue';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';

export default {
  name: 'GroupMembersApp',
  components: { MembersList },
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
    optionalFields: {
      type: Array,
      required: false,
      default: () => [],
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
  <members-list
    :source-id="groupId"
    :current-user-id="currentUserId"
    :members="formattedMembers"
    :optional-fields="optionalFields"
  />
</template>
