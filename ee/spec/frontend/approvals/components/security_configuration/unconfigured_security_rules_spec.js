import Vuex from 'vuex';
import UnconfiguredSecurityRules from 'ee/approvals/components/security_configuration/unconfigured_security_rules.vue';
import UnconfiguredSecurityRule from 'ee/approvals/components/security_configuration/unconfigured_security_rule.vue';
import { createStoreOptions } from 'ee/approvals/stores';
import projectSettingsModule from 'ee/approvals/stores/modules/project_settings';
import { shallowMount, createLocalVue } from '@vue/test-utils';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('UnconfiguredSecurityRules component', () => {
  let wrapper;
  let store;
  let mockFetch;

  const TEST_PROJECT_ID = '7';

  const createWrapper = (props = {}) => {
    mockFetch = jest.fn();

    wrapper = shallowMount(UnconfiguredSecurityRules, {
      localVue,
      store,
      propsData: {
        ...props,
      },
      methods: {
        fetchSecurityConfiguration: mockFetch,
      },
      provide: {
        vulnerabilityCheckHelpPagePath: '',
        licenseCheckHelpPagePath: '',
      },
    });
  };

  beforeEach(() => {
    store = new Vuex.Store(
      createStoreOptions(projectSettingsModule(), { projectId: TEST_PROJECT_ID }),
    );
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('when created ', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('should fetch the security configuration', () => {
      expect(mockFetch).toHaveBeenCalled();
    });

    it('should render a unconfigured-security-rule component for every security rule ', () => {
      expect(wrapper.findAll(UnconfiguredSecurityRule).length).toBe(2);
    });
  });
});
