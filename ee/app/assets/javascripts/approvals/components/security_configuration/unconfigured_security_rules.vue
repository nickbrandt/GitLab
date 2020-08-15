<script>
import { mapState, mapActions } from 'vuex';
import { LICENSE_CHECK_NAME, VULNERABILITY_CHECK_NAME } from 'ee/approvals/constants';
import { s__ } from '~/locale';
import UnconfiguredSecurityRule from './unconfigured_security_rule.vue';

export default {
  components: {
    UnconfiguredSecurityRule,
  },
  props: {},
  inject: {
    vulnerabilityCheckHelpPagePath: {
      from: 'vulnerabilityCheckHelpPagePath',
      default: '',
    },
    licenseCheckHelpPagePath: {
      from: 'licenseCheckHelpPagePath',
      default: '',
    },
  },
  computed: {
    ...mapState('securityConfiguration', ['configuration']),
    ...mapState({
      rules: state => state.approvals.rules,
      hasApprovalsLoaded: state => state.approvals.hasLoaded,
      hasSecurityConfigurationLoaded: state => state.securityConfiguration.hasLoaded,
    }),
    isRulesLoading() {
      return !this.hasApprovalsLoaded || !this.hasSecurityConfigurationLoaded;
    },
    securityRules() {
      return [
        {
          name: VULNERABILITY_CHECK_NAME,
          description: s__(
            'SecurityApprovals|One or more of the security scanners must be enabled %{linkStart}more information%{linkEnd}',
          ),
          enableDescription: s__(
            'SecurityApprovals|Requires approval for vulnerabilties of Critical, High, or Unknown severity %{linkStart}more information%{linkEnd}',
          ),
          docsPath: this.vulnerabilityCheckHelpPagePath,
        },
        {
          name: LICENSE_CHECK_NAME,
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
  },
  created() {
    this.fetchSecurityConfiguration();
  },  
  methods: {
    ...mapActions('securityConfiguration', ['fetchSecurityConfiguration']),
    ...mapActions({ openCreateModal: 'createModal/open' }),
  },
};
</script>

<template>
  <table class="table m-0">
    <tbody>
      <unconfigured-security-rule
        v-for="securityRule in securityRules"
        :key="securityRule.name"
        :configuration="configuration"
        :rules="rules"
        :is-loading="isRulesLoading"
        :match-rule="securityRule"
        @enable="openCreateModal({ defaultRuleName: securityRule.name })"
      />
    </tbody>
  </table>
</template>
