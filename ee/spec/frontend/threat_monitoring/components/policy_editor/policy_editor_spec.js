import { shallowMount } from '@vue/test-utils';
import PolicyEditorApp from 'ee/threat_monitoring/components/policy_editor/policy_editor.vue';
import PolicyPreview from 'ee/threat_monitoring/components/policy_editor/policy_preview.vue';
import PolicyRuleBuilder from 'ee/threat_monitoring/components/policy_editor/policy_rule_builder.vue';
import NetworkPolicyEditor from 'ee/threat_monitoring/components/network_policy_editor.vue';
import createStore from 'ee/threat_monitoring/store';
import {
  RuleDirectionInbound,
  PortMatchModeAny,
  RuleTypeEndpoint,
  EditorModeYAML,
  EndpointMatchModeLabel,
} from 'ee/threat_monitoring/components/policy_editor/constants';
import fromYaml from 'ee/threat_monitoring/components/policy_editor/lib/from_yaml';

describe('PolicyEditorApp component', () => {
  let store;
  let wrapper;

  const factory = ({ propsData, state, data } = {}) => {
    store = createStore();
    Object.assign(store.state.threatMonitoring, {
      ...state,
    });

    wrapper = shallowMount(PolicyEditorApp, {
      propsData: {
        ...propsData,
      },
      store,
      data,
    });
  };

  const findRuleEditor = () => wrapper.find('[data-testid="rule-editor"]');
  const findYamlEditor = () => wrapper.find('[data-testid="yaml-editor"]');
  const findPreview = () => wrapper.find(PolicyPreview);
  const findAddRuleButton = () => wrapper.find('[data-testid="add-rule"]');
  const findYAMLParsingAlert = () => wrapper.find('[data-testid="parsing-alert"]');
  const findNetworkPolicyEditor = () => wrapper.find(NetworkPolicyEditor);

  beforeEach(() => {
    factory();
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('renders the policy editor layout', () => {
    expect(wrapper.find('section').element).toMatchSnapshot();
  });

  it('does not render yaml editor', () => {
    expect(findYamlEditor().exists()).toBe(false);
  });

  it('does not render parsing error alert', () => {
    expect(findYAMLParsingAlert().exists()).toBe(false);
  });

  describe('given .yaml editor mode is enabled', () => {
    beforeEach(() => {
      factory({
        data: () => ({
          editorMode: EditorModeYAML,
        }),
      });
    });

    it('does not render rule editor', () => {
      expect(findRuleEditor().exists()).toBe(false);
    });

    it('renders yaml editor', () => {
      const editor = findYamlEditor();
      expect(editor.exists()).toBe(true);
      expect(editor.element).toMatchSnapshot();
    });

    it('updates policy on yaml editor value change', async () => {
      const manifest = `apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
description: test description
metadata:
  name: test-policy
spec:
  endpointSelector:
    matchLabels:
      network-policy.gitlab.com/disabled_by: gitlab
      foo: bar
  ingress:
  - fromEndpoints:
    - matchLabels:
        foo: bar`;
      findNetworkPolicyEditor().vm.$emit('input', manifest);

      expect(wrapper.vm.policy).toMatchObject({
        name: 'test-policy',
        description: 'test description',
        isEnabled: false,
        endpointMatchMode: EndpointMatchModeLabel,
        endpointLabels: 'foo:bar',
        rules: [
          {
            ruleType: RuleTypeEndpoint,
            matchLabels: 'foo:bar',
          },
        ],
      });
    });
  });

  describe('given there is a name change', () => {
    let initialValue;

    beforeEach(() => {
      initialValue = findPreview().props('policyYaml');
      wrapper.find("[id='policyName']").vm.$emit('input', 'new');
    });

    it('updates policy yaml preview', () => {
      expect(findPreview().props('policyYaml')).not.toEqual(initialValue);
    });
  });

  describe('given there is a rule change', () => {
    let initialValue;

    beforeEach(() => {
      initialValue = findPreview().props('policyDescription');
      wrapper.find("[data-testid='add-rule']").vm.$emit('click');
    });

    it('updates policy description preview', () => {
      expect(findPreview().props('policyDescription')).not.toEqual(initialValue);
    });
  });

  it('adds a new rule', async () => {
    expect(wrapper.findAll(PolicyRuleBuilder).length).toEqual(0);
    const button = findAddRuleButton();
    button.vm.$emit('click');
    button.vm.$emit('click');
    await wrapper.vm.$nextTick();
    const elements = wrapper.findAll(PolicyRuleBuilder);
    expect(elements.length).toEqual(2);

    elements.wrappers.forEach((builder, idx) => {
      expect(builder.props().rule).toMatchObject({
        ruleType: RuleTypeEndpoint,
        direction: RuleDirectionInbound,
        matchLabels: '',
        portMatchMode: PortMatchModeAny,
        ports: '',
      });
      expect(builder.props().endpointSelectorDisabled).toEqual(idx !== 0);
    });
  });

  it('updates yaml editor value on switch to yaml editor', async () => {
    wrapper.find("[id='policyName']").vm.$emit('input', 'test-policy');
    wrapper.find("[data-testid='editor-mode']").vm.$emit('input', EditorModeYAML);
    await wrapper.vm.$nextTick();

    const editor = findNetworkPolicyEditor();
    expect(editor.exists()).toBe(true);
    expect(fromYaml(editor.props('value'))).toMatchObject({
      name: 'test-policy',
    });
  });

  describe('given there is a yaml parsing error', () => {
    beforeEach(() => {
      factory({
        data: () => ({
          yamlEditorError: {},
        }),
      });
    });

    it('renders parsing error alert', () => {
      expect(findYAMLParsingAlert().exists()).toBe(true);
    });

    it('disables add rule button', () => {
      expect(findAddRuleButton().props('disabled')).toBe(true);
    });
  });
});
