<script>
import { mapState } from 'vuex';

const INPUT_ID = 'merge_request[approval_rules_attributes][][id]';
const INPUT_SOURCE_ID = 'merge_request[approval_rules_attributes][][approvals_required]';
const INPUT_NAME = 'merge_request[approval_rules_attributes][][name]';
const INPUT_APPROVALS_REQUIRED = 'merge_request[approval_rules_attributes][][approvals_required]';
const INPUT_USER_IDS = 'merge_request[approval_rules_attributes][][user_ids][]';
const INPUT_GROUP_IDS = 'merge_request[approval_rules_attributes][][group_ids][]';
const INPUT_DELETE = 'merge_request[approval_rules_attributes][][_destroy]';

export default {
  computed: {
    ...mapState(['settings']),
    ...mapState({
      rules: state => state.rules.rules,
      rulesToDelete: state => state.rules.rulesToDelete,
    }),
  },
  INPUT_ID,
  INPUT_SOURCE_ID,
  INPUT_NAME,
  INPUT_APPROVALS_REQUIRED,
  INPUT_USER_IDS,
  INPUT_GROUP_IDS,
  INPUT_DELETE,
};
</script>

<template>
  <div v-if="settings.canEdit">
    <div v-for="id in rulesToDelete" :key="id">
      <input :value="id" :name="$options.INPUT_ID" type="hidden" />
      <input :value="1" :name="$options.INPUT_DELETE" type="hidden" />
    </div>
    <div v-for="rule in rules" :key="rule.id">
      <input v-if="!rule.isNew" :value="rule.id" :name="$options.INPUT_ID" type="hidden" />
      <input
        v-if="rule.isNew && rule.sourceId"
        :value="rule.sourceId"
        :name="$options.INPUT_SOURCE_ID"
        type="hidden"
      />
      <input
        :value="rule.approvalsRequired"
        :name="$options.INPUT_APPROVALS_REQUIRED"
        type="hidden"
      />
      <input :value="rule.name" :name="$options.INPUT_NAME" type="hidden" />
      <input
        v-for="user in rule.users"
        :key="user.id"
        :value="user.id"
        :name="$options.INPUT_USER_IDS"
        type="hidden"
      />
      <input
        v-for="group in rule.groups"
        :key="group.id"
        :value="group.id"
        :name="$options.INPUT_GROUP_IDS"
        type="hidden"
      />
    </div>
  </div>
</template>
