import { createLocalVue, shallowMount, mount } from '@vue/test-utils';
import Vuex from 'vuex';
import Vue from 'vue';
import store from 'ee/analytics/cycle_analytics/store';
import Component from 'ee/analytics/cycle_analytics/components/base.vue';
import { GlEmptyState, GlDaterangePicker } from '@gitlab/ui';
import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import GroupsDropdownFilter from 'ee/analytics/shared/components/groups_dropdown_filter.vue';
import ProjectsDropdownFilter from 'ee/analytics/shared/components/projects_dropdown_filter.vue';
import SummaryTable from 'ee/analytics/cycle_analytics/components/summary_table.vue';
import StageTable from 'ee/analytics/cycle_analytics/components/stage_table.vue';
import 'bootstrap';
import '~/gl_dropdown';
import Scatterplot from 'ee/analytics/shared/components/scatterplot.vue';
import waitForPromises from 'helpers/wait_for_promises';
import httpStatusCodes from '~/lib/utils/http_status';
import * as mockData from '../mock_data';

const noDataSvgPath = 'path/to/no/data';
const noAccessSvgPath = 'path/to/no/access';
const emptyStateSvgPath = 'path/to/empty/state';
const baseStagesEndpoint = '/-/analytics/cycle_analytics/stages';

const localVue = createLocalVue();
localVue.use(Vuex);

const defaultStubs = {
  'summary-table': true,
  'stage-event-list': true,
  'stage-nav-item': true,
  'tasks-by-type-chart': true,
};

function createComponent({
  opts = {},
  shallow = true,
  withStageSelected = false,
  scatterplotEnabled = true,
  tasksByTypeChartEnabled = true,
  customizableCycleAnalyticsEnabled = false,
} = {}) {
  const func = shallow ? shallowMount : mount;
  const comp = func(Component, {
    localVue,
    store,
    propsData: {
      emptyStateSvgPath,
      noDataSvgPath,
      noAccessSvgPath,
      baseStagesEndpoint,
    },
    provide: {
      glFeatures: {
        cycleAnalyticsScatterplotEnabled: scatterplotEnabled,
        tasksByTypeChart: tasksByTypeChartEnabled,
        customizableCycleAnalytics: customizableCycleAnalyticsEnabled,
      },
    },
    ...opts,
  });

  if (withStageSelected) {
    comp.vm.$store.dispatch('setSelectedGroup', {
      ...mockData.group,
    });

    comp.vm.$store.dispatch('receiveGroupStagesAndEventsSuccess', {
      ...mockData.customizableStagesAndEvents,
    });

    comp.vm.$store.dispatch('receiveStageDataSuccess', mockData.issueEvents);
  }
  return comp;
}

describe('Cycle Analytics component', () => {
  let wrapper;
  let mock;

  const selectStageNavItem = index =>
    wrapper
      .find(StageTable)
      .findAll('.stage-nav-item')
      .at(index);

  const displaysProjectsDropdownFilter = flag => {
    expect(wrapper.find(ProjectsDropdownFilter).exists()).toBe(flag);
  };

  const displaysDateRangePicker = flag => {
    expect(wrapper.find(GlDaterangePicker).exists()).toBe(flag);
  };

  const displaysSummaryTable = flag => {
    expect(wrapper.find(SummaryTable).exists()).toBe(flag);
  };

  const displaysStageTable = flag => {
    expect(wrapper.find(StageTable).exists()).toBe(flag);
  };

  const displaysDurationScatterPlot = flag => {
    expect(wrapper.find(Scatterplot).exists()).toBe(flag);
  };

  beforeEach(() => {
    mock = new MockAdapter(axios);
    wrapper = createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
    mock.restore();
  });

  describe('mounted', () => {
    const actionSpies = {
      setDateRange: jest.fn(),
    };

    beforeEach(() => {
      jest.spyOn(global.Date, 'now').mockImplementation(() => new Date(mockData.endDate));
      wrapper = createComponent({ opts: { methods: actionSpies } });
    });

    describe('initDateRange', () => {
      it('dispatches setDateRange with skipFetch=true', () => {
        expect(actionSpies.setDateRange).toHaveBeenCalledWith({
          skipFetch: true,
          startDate: mockData.startDate,
          endDate: mockData.endDate,
        });
      });
    });
  });

  describe('displays the components as required', () => {
    describe('before a filter has been selected', () => {
      it('displays an empty state', () => {
        const emptyState = wrapper.find(GlEmptyState);

        expect(emptyState.exists()).toBe(true);
        expect(emptyState.props('svgPath')).toBe(emptyStateSvgPath);
      });

      it('displays the groups filter', () => {
        expect(wrapper.find(GroupsDropdownFilter).exists()).toBe(true);
        expect(wrapper.find(GroupsDropdownFilter).props('queryParams')).toEqual(
          wrapper.vm.$options.groupsQueryParams,
        );
      });

      it('does not display the projects filter', () => {
        displaysProjectsDropdownFilter(false);
      });

      it('does not display the date range picker', () => {
        displaysDateRangePicker(false);
      });

      it('does not display the summary table', () => {
        displaysSummaryTable(false);
      });

      it('does not display the stage table', () => {
        displaysStageTable(false);
      });

      it('does not display the duration scatter plot', () => {
        displaysDurationScatterPlot(false);
      });
    });

    describe('after a filter has been selected', () => {
      describe('the user has access to the group', () => {
        beforeEach(() => {
          wrapper = createComponent({ withStageSelected: true, tasksByTypeChartEnabled: false });
        });

        it('hides the empty state', () => {
          expect(wrapper.find(GlEmptyState).exists()).toBe(false);
        });

        it('displays the projects filter', () => {
          displaysProjectsDropdownFilter(true);

          expect(wrapper.find(ProjectsDropdownFilter).props()).toEqual(
            expect.objectContaining({
              queryParams: wrapper.vm.$options.projectsQueryParams,
              groupId: mockData.group.id,
              multiSelect: wrapper.vm.$options.multiProjectSelect,
            }),
          );
        });

        it('displays the date range picker', () => {
          displaysDateRangePicker(true);
        });

        it('displays the summary table', () => {
          displaysSummaryTable(true);
        });

        it('displays the stage table', () => {
          displaysStageTable(true);
        });

        it('does not display the add stage button', () => {
          expect(wrapper.find('.js-add-stage-button').exists()).toBe(false);
        });

        describe('with no durationData', () => {
          it('displays the duration chart', () => {
            expect(wrapper.find(Scatterplot).exists()).toBe(false);
          });

          it('displays the no data message', () => {
            const element = wrapper.find({ ref: 'duration-chart-no-data' });

            expect(element.exists()).toBe(true);
            expect(element.text()).toBe(
              'There is no data available. Please change your selection.',
            );
          });
        });

        describe('with durationData', () => {
          beforeEach(() => {
            mock = new MockAdapter(axios);
            wrapper.vm.$store.dispatch('setDateRange', {
              skipFetch: true,
              startDate: mockData.startDate,
              endDate: mockData.endDate,
            });
            wrapper.vm.$store.dispatch(
              'receiveDurationDataSuccess',
              mockData.transformedDurationData,
            );
          });

          it('displays the duration chart', () => {
            expect(wrapper.find(Scatterplot).exists()).toBe(true);
          });
        });

        describe('StageTable', () => {
          beforeEach(() => {
            mock = new MockAdapter(axios);
            wrapper = createComponent({
              opts: {
                stubs: {
                  'stage-event-list': true,
                  'summary-table': true,
                  'add-stage-button': true,
                  'stage-table-header': true,
                },
              },
              shallow: false,
              withStageSelected: true,
              tasksByTypeChartEnabled: false,
            });
          });

          it('has the first stage selected by default', () => {
            const first = selectStageNavItem(0);
            const second = selectStageNavItem(1);

            expect(first.classes('active')).toBe(true);
            expect(second.classes('active')).toBe(false);
          });

          it('can navigate to different stages', done => {
            selectStageNavItem(2).trigger('click');

            Vue.nextTick(() => {
              const first = selectStageNavItem(0);
              const third = selectStageNavItem(2);

              expect(third.classes('active')).toBe(true);
              expect(first.classes('active')).toBe(false);
              done();
            });
          });
        });
      });

      describe('the user does not have access to the group', () => {
        beforeEach(() => {
          mock = new MockAdapter(axios);
          wrapper.vm.$store.dispatch('setSelectedGroup', {
            ...mockData.group,
          });

          wrapper.vm.$store.state.errorCode = 403;
        });

        it('renders the no access information', () => {
          const emptyState = wrapper.find(GlEmptyState);

          expect(emptyState.exists()).toBe(true);
          expect(emptyState.props('svgPath')).toBe(noAccessSvgPath);
        });

        it('does not display the projects filter', () => {
          displaysProjectsDropdownFilter(false);
        });

        it('does not display the date range picker', () => {
          displaysDateRangePicker(false);
        });

        it('does not display the summary table', () => {
          displaysSummaryTable(false);
        });

        it('does not display the stage table', () => {
          displaysStageTable(false);
        });

        it('does not display the add stage button', () => {
          expect(wrapper.find('.js-add-stage-button').exists()).toBe(false);
        });
      });

      describe('with customizableCycleAnalytics=true', () => {
        beforeEach(() => {
          mock = new MockAdapter(axios);
          wrapper = createComponent({
            opts: {
              stubs: defaultStubs,
            },
            shallow: false,
            withStageSelected: true,
            customizableCycleAnalyticsEnabled: true,
            tasksByTypeChartEnabled: false,
          });
        });

        afterEach(() => {
          wrapper.destroy();
          mock.restore();
        });

        it('will display the add stage button', () => {
          expect(wrapper.find('.js-add-stage-button').exists()).toBe(true);
        });
      });

      describe('with tasksByTypeChart=true', () => {
        beforeEach(() => {
          mock = new MockAdapter(axios);
          wrapper = createComponent({
            opts: {
              stubs: defaultStubs,
            },
            shallow: false,
            withStageSelected: true,
            customizableCycleAnalyticsEnabled: false,
            tasksByTypeChartEnabled: true,
          });
        });

        afterEach(() => {
          wrapper.destroy();
          mock.restore();
        });
        it('displays the tasks by type chart', () => {
          expect(wrapper.find('.tasks-by-type-chart').exists()).toBe(true);
        });
      });

      describe('with tasksByTypeChart=false', () => {
        beforeEach(() => {
          mock = new MockAdapter(axios);
          wrapper = createComponent({
            opts: {
              stubs: defaultStubs,
            },
            shallow: false,
            withStageSelected: true,
            customizableCycleAnalyticsEnabled: false,
            tasksByTypeChartEnabled: false,
          });
        });

        afterEach(() => {
          wrapper.destroy();
          mock.restore();
        });

        it('does not render the tasks by type chart', () => {
          expect(wrapper.find('.tasks-by-type-chart').exists()).toBe(false);
        });
      });
    });
  });

  describe('with failed requests while loading', () => {
    const { full_path: groupId } = mockData.group;

    function mockRequestCycleAnalyticsData({
      overrides = {},
      mockFetchStageData = true,
      mockFetchStageMedian = true,
      mockFetchDurationData = true,
      mockFetchTasksByTypeData = true,
    }) {
      const defaultStatus = 200;
      const defaultRequests = {
        fetchSummaryData: {
          status: defaultStatus,
          endpoint: `/-/analytics/cycle_analytics/summary`,
          response: [...mockData.summaryData],
        },
        fetchGroupStagesAndEvents: {
          status: defaultStatus,
          endpoint: `/-/analytics/cycle_analytics/stages`,
          response: { ...mockData.customizableStagesAndEvents },
        },
        fetchGroupLabels: {
          status: defaultStatus,
          endpoint: `/groups/${groupId}/-/labels`,
          response: [...mockData.groupLabels],
        },
        ...overrides,
      };

      if (mockFetchTasksByTypeData) {
        mock
          .onGet(/analytics\/type_of_work\/tasks_by_type/)
          .reply(defaultStatus, { ...mockData.tasksByTypeData });
      }

      if (mockFetchDurationData) {
        mock
          .onGet(/analytics\/cycle_analytics\/stages\/\d+\/duration_chart/)
          .reply(defaultStatus, [...mockData.rawDurationData]);
      }

      if (mockFetchStageMedian) {
        mock
          .onGet(/analytics\/cycle_analytics\/stages\/\d+\/median/)
          .reply(defaultStatus, { value: null });
      }

      if (mockFetchStageData) {
        mock
          .onGet(/analytics\/cycle_analytics\/stages\/\d+\/records/)
          .reply(defaultStatus, mockData.issueEvents);
      }

      Object.values(defaultRequests).forEach(({ endpoint, status, response }) => {
        mock.onGet(endpoint).replyOnce(status, response);
      });
    }

    beforeEach(() => {
      setFixtures('<div class="flash-container"></div>');

      mock = new MockAdapter(axios);
      wrapper = createComponent();
    });

    afterEach(() => {
      wrapper.destroy();
      mock.restore();
    });

    const findFlashError = () => document.querySelector('.flash-container .flash-text');
    const selectGroupAndFindError = msg => {
      wrapper.vm.onGroupSelect(mockData.group);

      return waitForPromises().then(() => {
        expect(findFlashError().innerText.trim()).toEqual(msg);
      });
    };

    it('will display an error if the fetchSummaryData request fails', () => {
      expect(findFlashError()).toBeNull();

      mockRequestCycleAnalyticsData({
        overrides: {
          fetchSummaryData: {
            status: httpStatusCodes.NOT_FOUND,
            endpoint: '/-/analytics/cycle_analytics/summary',
            response: { response: { status: httpStatusCodes.NOT_FOUND } },
          },
        },
      });

      return selectGroupAndFindError(
        'There was an error while fetching cycle analytics summary data.',
      );
    });

    it('will display an error if the fetchGroupLabels request fails', () => {
      expect(findFlashError()).toBeNull();

      mockRequestCycleAnalyticsData({
        overrides: {
          fetchGroupLabels: {
            status: httpStatusCodes.NOT_FOUND,
            response: { response: { status: httpStatusCodes.NOT_FOUND } },
          },
        },
      });

      return selectGroupAndFindError(
        'There was an error fetching label data for the selected group',
      );
    });

    it('will display an error if the fetchGroupStagesAndEvents request fails', () => {
      expect(findFlashError()).toBeNull();

      mockRequestCycleAnalyticsData({
        overrides: {
          fetchGroupStagesAndEvents: {
            endPoint: '/-/analytics/cycle_analytics/stages',
            status: httpStatusCodes.NOT_FOUND,
            response: { response: { status: httpStatusCodes.NOT_FOUND } },
          },
        },
      });

      return selectGroupAndFindError('There was an error fetching cycle analytics stages.');
    });

    it('will display an error if the fetchStageData request fails', () => {
      expect(findFlashError()).toBeNull();

      mockRequestCycleAnalyticsData({
        mockFetchStageData: false,
      });

      return selectGroupAndFindError('There was an error fetching data for the selected stage');
    });

    it('will display an error if the fetchTasksByTypeData request fails', () => {
      expect(findFlashError()).toBeNull();

      mockRequestCycleAnalyticsData({ mockFetchTasksByTypeData: false });

      return selectGroupAndFindError(
        'There was an error fetching data for the tasks by type chart',
      );
    });

    it('will display an error if the fetchDurationData request fails', () => {
      expect(findFlashError()).toBeNull();

      mockRequestCycleAnalyticsData({
        mockFetchDurationData: false,
      });

      wrapper.vm.onGroupSelect(mockData.group);

      return waitForPromises().catch(() => {
        expect(findFlashError().innerText.trim()).toEqual(
          'There was an error while fetching cycle analytics duration data.',
        );
      });
    });

    it('will display an error if the fetchStageMedian request fails', () => {
      expect(findFlashError()).toBeNull();

      mockRequestCycleAnalyticsData({
        mockFetchStageMedian: false,
      });

      wrapper.vm.onGroupSelect(mockData.group);

      return waitForPromises().catch(() => {
        expect(findFlashError().innerText.trim()).toEqual(
          'There was an error while fetching cycle analytics duration data.',
        );
      });
    });
  });
});
