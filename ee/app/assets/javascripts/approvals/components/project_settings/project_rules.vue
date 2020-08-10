<script>
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { mapState, mapActions } from 'vuex';
import { s__, n__, sprintf } from '~/locale';
import { RULE_TYPE_ANY_APPROVER, RULE_TYPE_REGULAR } from '../../constants';
import UserAvatarList from '~/vue_shared/components/user_avatar/user_avatar_list.vue';
import Rules from '../rules.vue';
import RuleControls from '../rule_controls.vue';
import EmptyRule from '../empty_rule.vue';
import RuleInput from '../mr_edit/rule_input.vue';
import RuleBranches from '../rule_branches.vue';
import UnconfiguredSecurityRule from '../security_configuration/unconfigured_security_rule.vue';

export default {
  components: {
    RuleControls,
    Rules,
    UserAvatarList,
    EmptyRule,
    RuleInput,
    RuleBranches,
    UnconfiguredSecurityRule,
  },
  // TODO: Remove feature flag in https://gitlab.com/gitlab-org/gitlab/-/issues/235114
  mixins: [glFeatureFlagsMixin()],
  inject: {
    securityConfigurationPath: {
      type: String,
      required: true,
      from: 'securityConfigurationPath',
      default: '',
    },
    vulnerabilityCheckHelpPagePath: {
      type: String,
      required: true,
      from: 'vulnerabilityCheckHelpPagePath',
      default: '',
    },
    licenseCheckHelpPagePath: {
      type: String,
      required: true,
      from: 'licenseCheckHelpPagePath',
      default: '',
    },
  },
  computed: {
    ...mapState(['settings']),
    ...mapState({
      rules: state => state.approvals.rules,
      hasApprovalsLoaded: state => state.approvals.hasLoaded,
      hasSecurityConfigurationLoaded: state => state.securityConfiguration.hasLoaded,
    }),
    ...mapState('securityConfiguration', ['configuration']),
    hasNamedRule() {
      return this.rules.some(rule => rule.ruleType === RULE_TYPE_REGULAR);
    },
    hasAnyRule() {
      return (
        this.settings.allowMultiRule &&
        !this.rules.some(rule => rule.ruleType === RULE_TYPE_ANY_APPROVER)
      );
    },
    isRulesLoading() {
      return !this.hasApprovalsLoaded || !this.hasSecurityConfigurationLoaded;
    },
    securityRules() {
      return [
        {
          name: 'Vulnerability-Check',
          description: s__(
            'SecurityApprovals|One or more of the security scanners must be enabled %{linkStart}more information%{linkEnd}',
          ),
          enableDescription: s__(
            'SecurityApprovals|Requires approval for vulnerabilties of Critical, High, or Unknown severity %{linkStart}more information%{linkEnd}',
          ),
          docsPath: this.vulnerabilityCheckHelpPagePath,
        },
        {
          name: 'License-Check',
          description: s__(
            'SecurityApprovals|License Scanning must be enabled %{linkStart}more information%{linkEnd}',
          ),
          enableDescription: s__(
            'SecurityApprovals|Requires license policy rules for licenses of Allowed, or Denied %{linkStart}more information%{linkEnd}',
          ),
          docsPath: this.licenseCheckHelpPagePath,
        },
      ];
    },
    // TODO: Remove feature flag in https://gitlab.com/gitlab-org/gitlab/-/issues/235114
    isApprovalSuggestionsEnabled() {
      return Boolean(this.glFeatures.approvalSuggestions);
    },
  },
  watch: {
    rules: {
      handler(newValue) {
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
    // TODO: Remove feature flag in https://gitlab.com/gitlab-org/gitlab/-/issues/235114
    if (this.isApprovalSuggestionsEnabled) {
      this.setSecurityConfigurationEndpoint(this.securityConfigurationPath);
      this.fetchSecurityConfiguration();
    }
  },
  methods: {
    ...mapActions(['addEmptyRule']),
    ...mapActions({ openCreateModal: 'createModal/open' }),
    ...mapActions('securityConfiguration', [
      'setSecurityConfigurationEndpoint',
      'fetchSecurityConfiguration',
    ]),
    summaryText(rule) {
      return this.settings.allowMultiRule
        ? this.summaryMultipleRulesText(rule)
        : this.summarySingleRuleText(rule);
    },
    membersCountText(rule) {
      return n__(
        'ApprovalRuleSummary|%d member',
        'ApprovalRuleSummary|%d members',
        rule.approvers.length,
      );
    },
    summarySingleRuleText(rule) {
      const membersCount = this.membersCountText(rule);

      return sprintf(
        n__(
          'ApprovalRuleSummary|%{count} approval required from %{membersCount}',
          'ApprovalRuleSummary|%{count} approvals required from %{membersCount}',
          rule.approvalsRequired,
        ),
        { membersCount, count: rule.approvalsRequired },
      );
    },
    summaryMultipleRulesText(rule) {
      return sprintf(
        n__(
          '%{count} approval required from %{name}',
          '%{count} approvals required from %{name}',
          rule.approvalsRequired,
        ),
        { name: rule.name, count: rule.approvalsRequired },
      );
    },
    canEdit(rule) {
      const { canEdit, allowMultiRule } = this.settings;

      return canEdit && (!allowMultiRule || !rule.hasSource);
    },
  },
};
</script>

<template>
  <rules :rules="rules">
    <template #thead="{ name, members, approvalsRequired, branches }">
      <tr class="d-none d-sm-table-row">
        <th class="w-25">{{ hasNamedRule ? name : members }}</th>
        <th :class="settings.allowMultiRule ? 'w-50 d-none d-sm-table-cell' : 'w-75'">
          <span v-if="hasNamedRule">{{ members }}</span>
        </th>
        <th v-if="settings.allowMultiRule">{{ branches }}</th>
        <th>{{ approvalsRequired }}</th>
        <th></th>
      </tr>
    </template>
    <template #tbody="{ rules }">
      <template v-for="(rule, index) in rules">
        <empty-rule
          v-if="rule.ruleType === 'any_approver'"
          :key="index"
          :rule="rule"
          :allow-multi-rule="settings.allowMultiRule"
          :is-mr-edit="false"
          :eligible-approvers-docs-path="settings.eligibleApproversDocsPath"
          :can-edit="canEdit(rule)"
        />
        <tr v-else :key="index">
          <td class="js-name">{{ rule.name }}</td>
          <td class="js-members" :class="settings.allowMultiRule ? 'd-none d-sm-table-cell' : null">
            <user-avatar-list :items="rule.approvers" :img-size="24" empty-text="" />
          </td>
          <td v-if="settings.allowMultiRule" class="js-branches">
            <rule-branches :rule="rule" />
          </td>
          <td class="js-approvals-required">
            <rule-input :rule="rule" />
          </td>
          <td class="text-nowrap px-2 w-0 js-controls">
            <rule-controls v-if="canEdit(rule)" :rule="rule" />
          </td>
        </tr>
      </template>

      <!-- TODO: Remove feature flag in https://gitlab.com/gitlab-org/gitlab/-/issues/235114 -->
      <template v-if="isApprovalSuggestionsEnabled">
        <unconfigured-security-rule
          v-for="securityRule in securityRules"
          :key="securityRule.name"
          :configuration="configuration"
          :rules="rules"
          :is-loading="isRulesLoading"
          :match-rule="securityRule"
          @enable-btn-clicked="openCreateModal({ name: securityRule.name, initRuleField: true })"
        />
      </template>
    </template>
  </rules>
</template>
