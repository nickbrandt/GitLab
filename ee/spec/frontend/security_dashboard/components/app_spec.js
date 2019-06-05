import { shallowMount, createLocalVue } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import { TEST_HOST } from 'helpers/test_constants';

import SecurityDashboardApp from 'ee/security_dashboard/components/app.vue';
import Filters from 'ee/security_dashboard/components/filters.vue';
import SecurityDashboardTable from 'ee/security_dashboard/components/security_dashboard_table.vue';
import VulnerabilityChart from 'ee/security_dashboard/components/vulnerability_chart.vue';
import VulnerabilityCountList from 'ee/security_dashboard/components/vulnerability_count_list.vue';

import createStore from 'ee/security_dashboard/store';

const localVue = createLocalVue();

const projectsEndpoint = `${TEST_HOST}/projects`;
const vulnerabilitiesEndpoint = `${TEST_HOST}/vulnerabilities`;
const vulnerabilitiesCountEndpoint = `${TEST_HOST}/vulnerabilities_summary`;
const vulnerabilitiesHistoryEndpoint = `${TEST_HOST}/vulnerabilities_history`;

describe('Card security reports app', () => {
  let wrapper;
  let mock;
  let fetchProjectsSpy;
  let lockFilterSpy;

  const setup = () => {
    mock = new MockAdapter(axios);
    fetchProjectsSpy = jest.fn();
    lockFilterSpy = jest.fn();
  };

  const createComponent = props => {
    wrapper = shallowMount(SecurityDashboardApp, {
      localVue,
      store: createStore(),
      sync: false,
      methods: {
        lockFilter: lockFilterSpy,
        fetchProjects: fetchProjectsSpy,
      },
      propsData: {
        dashboardDocumentation: '',
        emptyStateSvgPath: '',
        projectsEndpoint,
        vulnerabilitiesEndpoint,
        vulnerabilitiesCountEndpoint,
        vulnerabilitiesHistoryEndpoint,
        vulnerabilityFeedbackHelpPath: `${TEST_HOST}/vulnerabilities_feedback_help`,
        ...props,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    mock.restore();
  });

  describe('default', () => {
    beforeEach(() => {
      setup();
      createComponent();
    });

    it('render sub components', () => {
      expect(wrapper.find(Filters).exists()).toBe(true);
      expect(wrapper.find(SecurityDashboardTable).exists()).toBe(true);
      expect(wrapper.find(VulnerabilityChart).exists()).toBe(true);
      expect(wrapper.find(VulnerabilityCountList).exists()).toBe(true);
    });

    it('fetches projects and does not lock projects filter', () => {
      expect(wrapper.vm.isLockedToProject).toBe(false);
      expect(fetchProjectsSpy).toHaveBeenCalled();
      expect(lockFilterSpy).not.toHaveBeenCalled();
    });
  });

  describe('with project lock', () => {
    const project = {
      id: 123,
      name: 'my-project',
    };
    beforeEach(() => {
      setup();
      createComponent({
        lockToProject: project,
      });
    });

    it('locks to given project and does not fetch projects', () => {
      expect(wrapper.vm.isLockedToProject).toBe(true);
      expect(fetchProjectsSpy).not.toHaveBeenCalled();
      expect(lockFilterSpy).toHaveBeenCalledWith({
        filterId: 'project_id',
        optionId: project.id,
      });
    });
  });
});
