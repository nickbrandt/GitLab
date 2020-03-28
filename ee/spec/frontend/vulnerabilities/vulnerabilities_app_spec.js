import { shallowMount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import { waitForMutation } from 'helpers/vue_test_utils_helper';
import createStore from 'ee/security_dashboard/store';
import VulnerabilitiesApp from 'ee/vulnerabilities/components/vulnerabilities_app.vue';
import VulnerabilityList from 'ee/vulnerabilities/components/vulnerability_list.vue';
import { vulnerabilities } from './mock_data';

describe('Vulnerabilities app component', () => {
  let store;
  let wrapper;

  const WORKING_ENDPOINT = 'WORKING_ENDPOINT';

  const mock = new MockAdapter(axios);

  const createWrapper = props => {
    store = createStore();

    return shallowMount(VulnerabilitiesApp, {
      propsData: {
        dashboardDocumentation: '#',
        emptyStateSvgPath: '#',
        vulnerabilitiesEndpoint: '',
        ...props,
      },
      store,
    });
  };

  beforeEach(() => {
    mock.onGet(WORKING_ENDPOINT).replyOnce(200, vulnerabilities);
    wrapper = createWrapper({ vulnerabilitiesEndpoint: WORKING_ENDPOINT });
    return waitForMutation(wrapper.vm.$store, `vulnerabilities/RECEIVE_VULNERABILITIES_SUCCESS`);
  });

  afterEach(() => {
    mock.restore();
    wrapper.destroy();
  });

  it('should pass the vulnerabilties to the vulnerabilites list', () => {
    const vulnerabilityList = wrapper.find(VulnerabilityList);

    expect(vulnerabilityList.props().vulnerabilities).toEqual(vulnerabilities);
  });
});
