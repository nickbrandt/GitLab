<script>
import { mapState, mapActions } from 'vuex';
import { RULE_TYPE_ANY_APPROVER, RULE_TYPE_REGULAR, RULE_NAME_ANY_APPROVER } from '../../constants';
import UserAvatarList from '~/vue_shared/components/user_avatar/user_avatar_list.vue';
import Rules from '../rules.vue';
import RuleControls from '../rule_controls.vue';
import EmptyRule from './empty_rule.vue';
import RuleInput from './rule_input.vue';

export default {
  components: {
    UserAvatarList,
    Rules,
    RuleControls,
    EmptyRule,
    RuleInput,
  },
  computed: {
    ...mapState(['settings']),
    ...mapState({
      rules: state => state.approvals.rules,
    }),
    hasNamedRule() {
      if (this.settings.allowMultiRule) {
        return this.rules.some(rule => rule.ruleType !== RULE_TYPE_ANY_APPROVER);
      }

      const [rule] = this.rules;
      return rule.ruleType
        ? rule.ruleType === RULE_TYPE_REGULAR
        : rule.name !== RULE_NAME_ANY_APPROVER;
    },
    canEdit() {
      return this.settings.canEdit;
    },
  },
  watch: {
    rules: {
      handler(newValue) {
        if (!this.settings.allowMultiRule && newValue.length === 0) {
          this.setEmptyRule();
        }
        if (
          this.settings.allowMultiRule &&
          !newValue.some(rule => rule.ruleType === RULE_TYPE_ANY_APPROVER)
        ) {
          this.addEmptyRule();
        }
      },
      immediate: true,
    },
  },
  methods: {
    ...mapActions(['setEmptyRule', 'addEmptyRule']),
  },
};
</script>

<template>
  <rules :rules="rules">
    <template slot="thead" slot-scope="{ name, members, approvalsRequired }">
      <tr>
        <th :class="hasNamedRule ? 'w-25' : 'w-75'">{{ hasNamedRule ? name : members }}</th>
        <th :class="hasNamedRule ? 'w-75' : null">
          <span v-if="hasNamedRule">{{ members }}</span>
        </th>
        <th>{{ approvalsRequired }}</th>
        <th></th>
      </tr>
    </template>
    <template slot="tbody" slot-scope="{ rules }">
      <template v-for="(rule, index) in rules">
        <empty-rule
          v-if="rule.ruleType === 'any_approver'"
          :key="index"
          :rule="rule"
          :allow-multi-rule="settings.allowMultiRule"
          :eligible-approvers-docs-path="settings.eligibleApproversDocsPath"
          :can-edit="canEdit"
        />
        <tr v-else :key="index">
          <td class="js-name">{{ rule.name }}</td>
          <td class="js-members" :class="settings.allowMultiRule ? 'd-none d-sm-table-cell' : null">
            <user-avatar-list :items="rule.approvers" :img-size="24" />
          </td>
          <td class="js-approvals-required">
            <rule-input :rule="rule" />
          </td>
          <td class="text-nowrap px-2 w-0 js-controls">
            <rule-controls v-if="canEdit" :rule="rule" />
          </td>
        </tr>
      </template>
    </template>
  </rules>
</template>
