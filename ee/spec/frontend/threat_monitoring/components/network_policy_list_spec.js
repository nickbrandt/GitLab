import { mount } from '@vue/test-utils';
import createStore from 'ee/threat_monitoring/store';
import NetworkPolicyList from 'ee/threat_monitoring/components/network_policy_list.vue';
import { GlTable } from '@gitlab/ui';

import { mockPoliciesResponse } from '../mock_data';

describe('NetworkPolicyList component', () => {
  let store;
  let wrapper;

  const factory = ({ propsData, state } = {}) => {
    store = createStore();
    Object.assign(store.state.networkPolicies, {
      isLoadingPolicies: false,
      policies: mockPoliciesResponse,
      ...state,
    });

    wrapper = mount(NetworkPolicyList, {
      propsData: {
        documentationPath: 'documentation_path',
        ...propsData,
      },
      store,
    });
  };

  const findEnvironmentsPicker = () => wrapper.find({ ref: 'environmentsPicker' });
  const findPoliciesTable = () => wrapper.find(GlTable);
  const findTableEmptyState = () => wrapper.find({ ref: 'tableEmptyState' });

  beforeEach(() => {
    factory({});
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('renders EnvironmentPicker', () => {
    expect(findEnvironmentsPicker().exists()).toBe(true);
  });

  it('renders policies table', () => {
    expect(findPoliciesTable().element).toMatchSnapshot();
  });

  describe('given there is a default environment with no data to display', () => {
    beforeEach(() => {
      factory({
        state: {
          policies: [],
        },
      });
    });

    it('shows the table empty state', () => {
      expect(findTableEmptyState().element).toMatchSnapshot();
    });
  });
});
