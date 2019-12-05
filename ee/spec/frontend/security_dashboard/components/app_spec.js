import { shallowMount, createLocalVue } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import { getParameterValues } from '~/lib/utils/url_utility';
import { TEST_HOST } from 'helpers/test_constants';

import SecurityDashboardApp from 'ee/security_dashboard/components/app.vue';
import Filters from 'ee/security_dashboard/components/filters.vue';
import SecurityDashboardTable from 'ee/security_dashboard/components/security_dashboard_table.vue';
import VulnerabilityChart from 'ee/security_dashboard/components/vulnerability_chart.vue';
import VulnerabilityCountList from 'ee/security_dashboard/components/vulnerability_count_list.vue';

import createStore from 'ee/security_dashboard/store';

const localVue = createLocalVue();

const pipelineId = 123;
const vulnerabilitiesEndpoint = `${TEST_HOST}/vulnerabilities`;
const vulnerabilitiesCountEndpoint = `${TEST_HOST}/vulnerabilities_summary`;
const vulnerabilitiesHistoryEndpoint = `${TEST_HOST}/vulnerabilities_history`;

jest.mock('~/lib/utils/url_utility', () => ({
  getParameterValues: jest.fn().mockReturnValue([]),
}));

describe('Security Dashboard app', () => {
  let wrapper;
  let mock;
  let lockFilterSpy;
  let setPipelineIdSpy;
  let store;

  const setup = () => {
    mock = new MockAdapter(axios);
    lockFilterSpy = jest.fn();
    setPipelineIdSpy = jest.fn();
  };

  const createComponent = props => {
    store = createStore();
    wrapper = shallowMount(SecurityDashboardApp, {
      localVue,
      store,
      sync: false,
      methods: {
        lockFilter: lockFilterSpy,
        setPipelineId: setPipelineIdSpy,
      },
      propsData: {
        dashboardDocumentation: '',
        vulnerabilitiesEndpoint,
        vulnerabilitiesCountEndpoint,
        vulnerabilitiesHistoryEndpoint,
        pipelineId,
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

    it('renders the filters', () => {
      expect(wrapper.find(Filters).exists()).toBe(true);
    });

    it('renders the security dashboard table ', () => {
      expect(wrapper.find(SecurityDashboardTable).exists()).toBe(true);
    });

    it('renders the vulnerability chart', () => {
      expect(wrapper.find(VulnerabilityChart).exists()).toBe(true);
    });

    it('does not render the vulnerability count list', () => {
      expect(wrapper.find(VulnerabilityCountList).exists()).toBe(false);
    });

    it('does not lock to a project', () => {
      expect(wrapper.vm.isLockedToProject).toBe(false);
    });

    it('does not lock project filters', () => {
      expect(lockFilterSpy).not.toHaveBeenCalled();
    });

    it('sets the pipeline id', () => {
      expect(setPipelineIdSpy).toHaveBeenCalledWith(pipelineId);
    });

    describe('when the total number of vulnerabilities change', () => {
      const newCount = 3;

      beforeEach(() => {
        localVue.set(store.state.vulnerabilities.pageInfo, 'total', newCount);
      });

      it('emits a vulnerabilitiesCountChanged event', () => {
        expect(wrapper.emitted('vulnerabilitiesCountChanged')).toEqual([[newCount]]);
      });
    });
  });

  describe('with project lock', () => {
    const project = {
      id: 123,
    };
    beforeEach(() => {
      setup();
      createComponent({
        lockToProject: project,
      });
    });

    it('renders the vulnerability count list', () => {
      expect(wrapper.find(VulnerabilityCountList).exists()).toBe(true);
    });

    it('locks to a given project', () => {
      expect(wrapper.vm.isLockedToProject).toBe(true);
    });

    it('locks the filters to a given project', () => {
      expect(lockFilterSpy).toHaveBeenCalledWith({
        filterId: 'project_id',
        optionId: project.id,
      });
    });
  });

  describe.each`
    endpointProp                        | Component
    ${'vulnerabilitiesCountEndpoint'}   | ${VulnerabilityCountList}
    ${'vulnerabilitiesHistoryEndpoint'} | ${VulnerabilityChart}
  `('with an empty $endpointProp', ({ endpointProp, Component }) => {
    beforeEach(() => {
      setup();
      createComponent({
        [endpointProp]: '',
      });
    });

    it(`does not show the ${Component.name}`, () => {
      expect(wrapper.find(Component).exists()).toBe(false);
    });
  });

  describe('dismissed vulnerabilities', () => {
    beforeEach(() => {
      getParameterValues.mockImplementation(() => [true]);
      setup();
    });

    afterEach(() => {
      getParameterValues.mockRestore();
    });

    it.each`
      description                                                        | getParameterValuesReturnValue | expected
      ${'hides dismissed vulnerabilities by default'}                    | ${[]}                         | ${true}
      ${'shows dismissed vulnerabilities if scope param is "all"'}       | ${['all']}                    | ${false}
      ${'hides dismissed vulnerabilities if scope param is "dismissed"'} | ${['dismissed']}              | ${true}
    `('$description', ({ getParameterValuesReturnValue, expected }) => {
      getParameterValues.mockImplementation(() => getParameterValuesReturnValue);
      createComponent();
      expect(wrapper.vm.$store.state.filters.hideDismissed).toBe(expected);
    });
  });
});
