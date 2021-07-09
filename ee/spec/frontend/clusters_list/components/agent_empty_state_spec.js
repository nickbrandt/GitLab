import { GlAlert, GlEmptyState, GlSprintf } from '@gitlab/ui';
import AgentEmptyState from 'ee/clusters_list/components/agent_empty_state.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

describe('AgentEmptyStateComponent', () => {
  let wrapper;

  const propsData = {
    image: '/image/path',
    projectPath: 'path/to/project',
    hasConfigurations: false,
  };

  const findConfigurationsAlert = () => wrapper.findComponent(GlAlert);
  const findIntegrationButton = () => wrapper.findByTestId('integration-primary-button');
  const findEmptyState = () => wrapper.findComponent(GlEmptyState);

  beforeEach(() => {
    wrapper = shallowMountExtended(AgentEmptyState, {
      propsData,
      stubs: { GlEmptyState, GlSprintf },
    });
  });

  afterEach(() => {
    if (wrapper) {
      wrapper.destroy();
      wrapper = null;
    }
  });

  describe('when there are no agent configurations in repository', () => {
    it('should render notification message box', () => {
      expect(findConfigurationsAlert().exists()).toBe(true);
    });

    it('should disable integration button', () => {
      expect(findIntegrationButton().attributes('disabled')).toBe('true');
    });
  });

  describe('when there is a list of agent configurations', () => {
    beforeEach(() => {
      propsData.hasConfigurations = true;
      wrapper = shallowMountExtended(AgentEmptyState, {
        propsData,
      });
    });
    it('should render content without notification message box', () => {
      expect(findEmptyState().exists()).toBe(true);
      expect(findConfigurationsAlert().exists()).toBe(false);
      expect(findIntegrationButton().attributes('disabled')).toBeUndefined();
    });
  });
});
