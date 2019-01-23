<script>
import { mapState, mapActions } from 'vuex';
import UserAvatarList from '~/vue_shared/components/user_avatar/user_avatar_list.vue';
import Rules from '../rules.vue';
import RuleControls from '../rule_controls.vue';

export default {
  components: {
    UserAvatarList,
    Rules,
    RuleControls,
  },
  computed: {
    ...mapState(['settings']),
    ...mapState({
      rules: state => state.approvals.rules,
    }),
  },
  methods: {
    ...mapActions(['putRule']),
  },
};
</script>

<template>
  <rules :rules="rules">
    <template slot="thead">
      <tr>
        <th>{{ s__('ApprovalRule|Name') }}</th>
        <th class="w-50 d-none d-sm-table-cell">{{ s__('ApprovalRule|Members') }}</th>
        <th>{{ s__('ApprovalRule|No. approvals required') }}</th>
        <th></th>
      </tr>
    </template>
    <template slot="tr" slot-scope="{ rule }">
      <td>{{ rule.name }}</td>
      <td class="d-none d-sm-table-cell">
        <user-avatar-list :items="rule.approvers" :img-size="24" />
      </td>
      <td>
        <input
          :value="rule.approvalsRequired"
          :disabled="!settings.canEdit"
          class="form-control mw-6em"
          type="number"
          min="0"
          @input="putRule({ id: rule.id, approvalsRequired: $event.target.value })"
        />
      </td>
      <td class="text-nowrap px-2 w-0"><rule-controls v-if="settings.canEdit" :rule="rule" /></td>
    </template>
  </rules>
</template>
