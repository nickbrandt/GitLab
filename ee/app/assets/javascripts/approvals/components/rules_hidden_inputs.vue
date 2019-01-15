<script>
import { mapState } from 'vuex';

export default {
  computed: {
    ...mapState(['settings']),
    ...mapState({
      rules: state => state.rules.rules,
    }),
  },
};
</script>

<template>
  <div v-if="settings.canEdit">
    <div v-for="rule in rules" :key="rule.id">
      <input
        v-if="!rule.isNew"
        :value="rule.id"
        name="merge_request[approval_rules_attributes][][id]"
        type="hidden"
      />
      <input
        v-if="rule.isNew && rule.sourceId"
        :value="rule.sourceId"
        name="merge_request[approval_rules_attributes][][approval_project_rule_id]"
        type="hidden"
      />
      <input
        :value="rule.approvalsRequired"
        name="merge_request[approval_rules_attributes][][approvals_required]"
        type="hidden"
      />
      <input
        :value="rule.name"
        name="merge_request[approval_rules_attributes][][name]"
        type="hidden"
      />
      <input
        v-for="user in rule.users"
        :key="user.id"
        :value="user.id"
        name="merge_request[approval_rules_attributes][][user_ids][]"
        type="hidden"
      />
      <input
        v-for="group in rule.groups"
        :key="group.id"
        :value="group.id"
        name="merge_request[approval_rules_attributes][][group_ids][]"
        type="hidden"
      />
    </div>
  </div>
</template>
