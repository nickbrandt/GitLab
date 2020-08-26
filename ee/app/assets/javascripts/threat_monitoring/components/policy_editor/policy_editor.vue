<script>
import { mapActions } from 'vuex';
import {
  GlFormGroup,
  GlFormSelect,
  GlFormInput,
  GlFormTextarea,
  GlToggle,
  GlSegmentedControl,
  GlButton,
} from '@gitlab/ui';
import { s__ } from '~/locale';
import EnvironmentPicker from '../environment_picker.vue';
import NetworkPolicyEditor from '../network_policy_editor.vue';
import PolicyRuleBuilder from './policy_rule_builder.vue';
import PolicyPreview from './policy_preview.vue';
import PolicyActionPicker from './policy_action_picker.vue';
import {
  EditorModeRule,
  EditorModeYAML,
  EndpointMatchModeAny,
  RuleTypeEndpoint,
} from './constants';
import { buildRule } from './lib/rules';

export default {
  components: {
    GlFormGroup,
    GlFormSelect,
    GlFormInput,
    GlFormTextarea,
    GlToggle,
    GlSegmentedControl,
    GlButton,
    EnvironmentPicker,
    NetworkPolicyEditor,
    PolicyRuleBuilder,
    PolicyPreview,
    PolicyActionPicker,
  },
  data() {
    return {
      editorMode: EditorModeRule,
      policy: {
        name: '',
        description: '',
        isEnabled: false,
        endpointMatchMode: EndpointMatchModeAny,
        endpointLabels: '',
        rules: [],
      },
    };
  },
  computed: {
    shouldShowRuleEditor() {
      return this.editorMode === EditorModeRule;
    },
    shouldShowYamlEditor() {
      return this.editorMode === EditorModeYAML;
    },
  },
  created() {
    this.fetchEnvironments();
  },
  methods: {
    ...mapActions('threatMonitoring', ['fetchEnvironments']),
    addRule() {
      this.policy.rules.push(buildRule(RuleTypeEndpoint));
    },
    updateEndpointMatchMode(mode) {
      this.policy.endpointMatchMode = mode;
    },
    updateEndpointLabels(labels) {
      this.policy.endpointLabels = labels;
    },
    updateRuleType(ruleIdx, ruleType) {
      const rule = this.policy.rules[ruleIdx];
      this.policy.rules.splice(ruleIdx, 1, buildRule(ruleType, rule));
    },
  },
  policyTypes: [{ value: 'networkPolicy', text: s__('NetworkPolicies|Network Policy') }],
  editorModes: [
    { value: EditorModeRule, text: s__('NetworkPolicies|Rule mode') },
    { value: EditorModeYAML, text: s__('NetworkPolicies|.yaml mode') },
  ],
};
</script>

<template>
  <section>
    <header class="my-3">
      <h2 class="h3 mb-1">
        {{ s__('NetworkPolicies|Policy description') }}
      </h2>
    </header>

    <div class="row">
      <div class="col-sm-6 col-md-4 col-lg-3 col-xl-2">
        <gl-form-group :label="s__('NetworkPolicies|Policy type')" label-for="policyType">
          <gl-form-select
            id="policyType"
            value="networkPolicy"
            :options="$options.policyTypes"
            disabled
          />
        </gl-form-group>
      </div>
      <div class="col-sm-6 col-md-6 col-lg-5 col-xl-4">
        <gl-form-group :label="s__('NetworkPolicies|Name')" label-for="policyName">
          <gl-form-input id="policyName" v-model="policy.name" />
        </gl-form-group>
      </div>
    </div>
    <div class="row">
      <div class="col-sm-12 col-md-10 col-lg-8 col-xl-6">
        <gl-form-group :label="s__('NetworkPolicies|Description')" label-for="policyDescription">
          <gl-form-textarea id="policyDescription" v-model="policy.description" />
        </gl-form-group>
      </div>
    </div>
    <div class="row">
      <environment-picker />
    </div>
    <div class="row">
      <div class="col-md-auto">
        <gl-form-group :label="s__('NetworkPolicies|Policy status')" label-for="policyStatus">
          <gl-toggle id="policyStatus" v-model="policy.isEnabled" />
        </gl-form-group>
      </div>
    </div>
    <div class="row">
      <div class="col-md-auto">
        <gl-form-group :label="s__('NetworkPolicies|Editor mode')" label-for="editorMode">
          <gl-segmented-control v-model="editorMode" :options="$options.editorModes" />
        </gl-form-group>
      </div>
    </div>
    <hr />
    <div v-if="shouldShowRuleEditor" class="row" data-testid="rule-editor">
      <div class="col-sm-12 col-md-6 col-lg-7 col-xl-8">
        <h4>{{ s__('NetworkPolicies|Rules') }}</h4>
        <policy-rule-builder
          v-for="(rule, idx) in policy.rules"
          :key="idx"
          class="gl-mb-4"
          :rule="rule"
          :endpoint-match-mode="policy.endpointMatchMode"
          :endpoint-labels="policy.endpointLabels"
          :endpoint-selector-disabled="idx > 0"
          @rule-type-change="updateRuleType(idx, $event)"
          @endpoint-match-mode-change="updateEndpointMatchMode"
          @endpoint-labels-change="updateEndpointLabels"
        />

        <div class="gl-p-3 gl-rounded-base gl-border-1 gl-border-solid gl-border-gray-100">
          <gl-button variant="link" category="primary" data-testid="add-rule" @click="addRule">{{
            s__('Network Policy|New rule')
          }}</gl-button>
        </div>

        <h4>{{ s__('NetworkPolicies|Actions') }}</h4>
        <policy-action-picker />
      </div>
      <div class="col-sm-12 col-md-6 col-lg-5 col-xl-4">
        <h5>{{ s__('NetworkPolicies|Policy preview') }}</h5>
        <policy-preview />
      </div>
    </div>
    <div v-if="shouldShowYamlEditor" class="row" data-testid="yaml-editor">
      <div class="col-sm-12 col-md-12 col-lg-10 col-xl-8">
        <div class="gl-rounded-base gl-border-1 gl-border-solid gl-border-gray-100">
          <h5 class="gl-m-0 gl-p-3 gl-bg-gray-10 gl-border-b-gray-100">
            {{ s__('NetworkPolicies|YAML editor') }}
          </h5>
          <network-policy-editor id="yamlEditor" value="" />
        </div>
      </div>
    </div>
    <hr />
    <div class="row">
      <div class="col-md-auto">
        <gl-button type="submit" category="primary" variant="success">{{
          s__('NetworkPolicies|Create policy')
        }}</gl-button>
        <gl-button category="secondary" variant="default">{{ __('Cancel') }}</gl-button>
      </div>
    </div>
  </section>
</template>
