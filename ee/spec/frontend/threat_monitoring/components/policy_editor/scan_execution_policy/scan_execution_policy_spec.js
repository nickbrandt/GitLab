import { shallowMount } from '@vue/test-utils';
import PolicyEditorLayout from 'ee/threat_monitoring/components/policy_editor/policy_editor_layout.vue';
import { DEFAULT_SCAN_EXECUTION_POLICY } from 'ee/threat_monitoring/components/policy_editor/scan_execution_policy/lib';
import ScanExecutionPolicyEditor from 'ee/threat_monitoring/components/policy_editor/scan_execution_policy/scan_execution_policy_editor.vue';
import waitForPromises from 'helpers/wait_for_promises';

describe('ScanExecutionPolicyEditor', () => {
  let wrapper;

  const factory = ({ propsData = {} } = {}) => {
    wrapper = shallowMount(ScanExecutionPolicyEditor, {
      propsData,
      provide: {
        threatMonitoringPath: '',
        projectId: 1,
      },
    });
  };

  const findPolicyEditorLayout = () => wrapper.findComponent(PolicyEditorLayout);

  beforeEach(() => {
    factory();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('calls the save policy funtion when "save-policy" is emitted', async () => {
    const savePolicySpy = jest.spyOn(wrapper.vm, 'savePolicy');
    expect(wrapper.vm.savePolicy).toHaveBeenCalledTimes(0);
    findPolicyEditorLayout().vm.$emit('save-policy');
    await waitForPromises();
    expect(wrapper.vm.savePolicy).toHaveBeenCalledTimes(1);
    savePolicySpy.mockRestore();
  });

  it('calls the remove policy funtion when "remove-policy" is emitted', async () => {
    const removePolicySpy = jest.spyOn(wrapper.vm, 'removePolicy');
    expect(wrapper.vm.removePolicy).toHaveBeenCalledTimes(0);
    findPolicyEditorLayout().vm.$emit('remove-policy');
    await waitForPromises();
    expect(wrapper.vm.removePolicy).toHaveBeenCalledTimes(1);
    removePolicySpy.mockRestore();
  });

  it('updates the policy yaml when "update-yaml" is emitted', async () => {
    const updateYamlSpy = jest.spyOn(wrapper.vm, 'updateYaml');
    const newManifest = 'new yaml!';
    expect(wrapper.vm.updateYaml).toHaveBeenCalledTimes(0);
    expect(findPolicyEditorLayout().attributes('yamleditorvalue')).toBe(
      DEFAULT_SCAN_EXECUTION_POLICY,
    );
    findPolicyEditorLayout().vm.$emit('update-yaml', newManifest);
    await waitForPromises();
    expect(wrapper.vm.updateYaml).toHaveBeenCalledTimes(1);
    expect(wrapper.vm.updateYaml).toHaveBeenCalledWith(newManifest);
    expect(findPolicyEditorLayout().attributes('yaml-editor-value')).toBe(newManifest);
    updateYamlSpy.mockRestore();
  });
});
