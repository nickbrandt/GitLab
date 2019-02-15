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
    canEdit(rule) {
      const { canEdit, allowMultiRule } = this.settings;

      return canEdit && (!allowMultiRule || !rule.hasSource);
    },
  },
};
</script>

<template>
  <rules :rules="rules">
    <template slot="thead" slot-scope="{ name, members, approvalsRequired }">
      <tr>
        <th v-if="settings.allowMultiRule">{{ name }}</th>
        <th :class="settings.allowMultiRule ? 'w-50 d-none d-sm-table-cell' : 'w-75'">
          {{ members }}
        </th>
        <th>{{ approvalsRequired }}</th>
        <th></th>
      </tr>
    </template>
    <template slot="tr" slot-scope="{ rule }">
      <td v-if="settings.allowMultiRule" class="js-name">{{ rule.name }}</td>
      <td class="js-members" :class="settings.allowMultiRule ? 'd-none d-sm-table-cell' : ''">
        <user-avatar-list :items="rule.approvers" :img-size="24" />
      </td>
      <td class="js-approvals-required">
        <input
          :value="rule.approvalsRequired"
          :disabled="!settings.canEdit"
          class="form-control mw-6em"
          type="number"
          :min="rule.minApprovalsRequired"
          @input="putRule({ id: rule.id, approvalsRequired: Number($event.target.value) })"
        />
      </td>
      <td class="text-nowrap px-2 w-0 js-controls">
        <rule-controls v-if="canEdit(rule)" :rule="rule" />
      </td>
    </template>
  </rules>
</template>
