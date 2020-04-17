<script>
import { __ } from '~/locale';
import { mapState, mapActions } from 'vuex';
import { RULE_TYPE_ANY_APPROVER, RULE_TYPE_REGULAR, RULE_NAME_ANY_APPROVER } from '../../constants';
import UserAvatarList from '~/vue_shared/components/user_avatar/user_avatar_list.vue';
import Rules from '../rules.vue';
import RuleControls from '../rule_controls.vue';
import EmptyRule from './empty_rule.vue';
import RuleInput from './rule_input.vue';

let targetBranchMutationObserver;

export default {
  components: {
    UserAvatarList,
    Rules,
    RuleControls,
    EmptyRule,
    RuleInput,
  },
  data() {
    return {
      targetBranch: '',
    };
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
    isEditPath() {
      return this.settings.mrSettingsPath;
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
  mounted() {
    if (this.isEditPath) {
      this.mergeRequestTargetBranchElement = document.querySelector('#merge_request_target_branch');

      this.targetBranch = this.mergeRequestTargetBranchElement?.value;

      if (this.targetBranch) {
        targetBranchMutationObserver = new MutationObserver(this.onTargetBranchMutation);
        targetBranchMutationObserver.observe(this.mergeRequestTargetBranchElement, {
          attributes: true,
          childList: false,
          subtree: false,
          attributeFilter: ['value'],
        });
      }
    }
  },
  beforeDestroy() {
    if (this.isEditPath && targetBranchMutationObserver) {
      targetBranchMutationObserver.disconnect();
      targetBranchMutationObserver = null;
    }
  },
  methods: {
    ...mapActions(['setEmptyRule', 'addEmptyRule', 'fetchRules']),
    onTargetBranchMutation() {
      const selectedTargetBranchValue = this.mergeRequestTargetBranchElement.value;

      if (this.targetBranch !== selectedTargetBranchValue) {
        this.targetBranch = selectedTargetBranchValue;
        this.fetchRules(this.targetBranch);
      }
    },
    indicatorText(rule) {
      if (rule.hasSource) {
        if (rule.overridden) {
          return __('Overridden');
        }
        return '';
      }
      return __('Added for this merge request');
    },
  },
};
</script>

<template>
  <rules :rules="rules">
    <template slot="thead" slot-scope="{ name, members, approvalsRequired }">
      <tr>
        <th :class="hasNamedRule ? 'w-25' : 'w-75'">{{ hasNamedRule ? name : members }}</th>
        <th :class="hasNamedRule ? 'w-50' : null">
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
          <td>
            <div class="js-name">{{ rule.name }}</div>
            <div ref="indicator" class="text-muted">
              {{ indicatorText(rule) }}
            </div>
          </td>
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
