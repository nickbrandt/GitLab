import { createLocalVue, shallowMount, mount } from '@vue/test-utils';
import Vuex from 'vuex';
import store from 'ee/analytics/cycle_analytics/store';
import Component from 'ee/analytics/cycle_analytics/components/base.vue';
import { GlEmptyState } from '@gitlab/ui';
import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import GroupsDropdownFilter from 'ee/analytics/shared/components/groups_dropdown_filter.vue';
import ProjectsDropdownFilter from 'ee/analytics/shared/components/projects_dropdown_filter.vue';
import RecentActivityCard from 'ee/analytics/cycle_analytics/components/recent_activity_card.vue';
import StageTable from 'ee/analytics/cycle_analytics/components/stage_table.vue';
import 'bootstrap';
import '~/gl_dropdown';
import DurationChart from 'ee/analytics/cycle_analytics/components/duration_chart.vue';
import Daterange from 'ee/analytics/shared/components/daterange.vue';
import TypeOfWorkCharts from 'ee/analytics/cycle_analytics/components/type_of_work_charts.vue';
import waitForPromises from 'helpers/wait_for_promises';
import httpStatusCodes from '~/lib/utils/http_status';
import * as commonUtils from '~/lib/utils/common_utils';
import * as urlUtils from '~/lib/utils/url_utility';
import { toYmd } from 'ee/analytics/shared/utils';
import * as mockData from '../mock_data';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import UrlSyncMixin from 'ee/analytics/shared/mixins/url_sync_mixin';

const noDataSvgPath = 'path/to/no/data';
const noAccessSvgPath = 'path/to/no/access';
const emptyStateSvgPath = 'path/to/empty/state';
const hideGroupDropDown = false;
const selectedGroup = convertObjectPropsToCamelCase(mockData.group);

const localVue = createLocalVue();
localVue.use(Vuex);

const defaultStubs = {
  'recent-activity-card': true,
  'stage-event-list': true,
  'stage-nav-item': true,
  'tasks-by-type-chart': true,
  'labels-selector': true,
  DurationChart: true,
};

function createComponent({
  opts = {
    stubs: defaultStubs,
  },
  shallow = true,
  withStageSelected = false,
  scatterplotEnabled = true,
  props = {},
} = {}) {
  const func = shallow ? shallowMount : mount;
  const comp = func(Component, {
    localVue,
    store,
    mixins: [UrlSyncMixin],
    propsData: {
      emptyStateSvgPath,
      noDataSvgPath,
      noAccessSvgPath,
      baseStagesEndpoint: mockData.endpoints.baseStagesEndpoint,
      hideGroupDropDown,
      ...props,
    },
    provide: {
      glFeatures: {
        cycleAnalyticsScatterplotEnabled: scatterplotEnabled,
      },
    },
    ...opts,
  });

  comp.vm.$store.dispatch('initializeCycleAnalytics', {
    createdAfter: mockData.startDate,
    createdBefore: mockData.endDate,
  });

  if (withStageSelected) {
    comp.vm.$store.dispatch('setSelectedGroup', {
      ...selectedGroup,
    });

    comp.vm.$store.dispatch(
      'receiveGroupStagesSuccess',
      mockData.customizableStagesAndEvents.stages,
    );

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

  const shouldSetUrlParams = result => {
    return wrapper.vm.$nextTick().then(() => {
      expect(urlUtils.setUrlParams).toHaveBeenCalledWith(result, window.location.href, true);
      expect(commonUtils.historyPushState).toHaveBeenCalled();
    });
  };

  const displaysProjectsDropdownFilter = flag => {
    expect(wrapper.find(ProjectsDropdownFilter).exists()).toBe(flag);
  };

  const displaysDateRangePicker = flag => {
    expect(wrapper.find(Daterange).exists()).toBe(flag);
  };

  const displaysRecentActivityCard = flag => {
    expect(wrapper.find(RecentActivityCard).exists()).toBe(flag);
  };

  const displaysStageTable = flag => {
    expect(wrapper.find(StageTable).exists()).toBe(flag);
  };

  const displaysDurationChart = flag => {
    expect(wrapper.find(DurationChart).exists()).toBe(flag);
  };

  const displaysTypeOfWork = flag => {
    expect(wrapper.find(TypeOfWorkCharts).exists()).toBe(flag);
  };

  beforeEach(() => {
    mock = new MockAdapter(axios);
    wrapper = createComponent();

    wrapper.vm.$store.dispatch('initializeCycleAnalytics', {
      createdAfter: mockData.startDate,
      createdBefore: mockData.endDate,
    });
  });

  afterEach(() => {
    wrapper.destroy();
    mock.restore();
    wrapper = null;
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

      it('does not display the recent activity table', () => {
        displaysRecentActivityCard(false);
      });

      it('does not display the stage table', () => {
        displaysStageTable(false);
      });

      it('does not display the duration chart', () => {
        displaysDurationChart(false);
      });

      it('does not display the add stage button', () => {
        expect(wrapper.find('.js-add-stage-button').exists()).toBe(false);
      });

      describe('hideGroupDropDown = true', () => {
        beforeEach(() => {
          mock = new MockAdapter(axios);
          wrapper = createComponent({
            props: {
              hideGroupDropDown: true,
            },
          });
        });

        it('does not render the group dropdown', () => {
          expect(wrapper.find(GroupsDropdownFilter).exists()).toBe(false);
        });
      });
    });

    describe('after a filter has been selected', () => {
      describe('the user has access to the group', () => {
        beforeEach(() => {
          wrapper = createComponent({
            withStageSelected: true,
          });
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

        it('displays the recent activity table', () => {
          displaysRecentActivityCard(true);
        });

        it('displays the stage table', () => {
          displaysStageTable(true);
        });

        it('displays the add stage button', () => {
          wrapper = createComponent({ shallow: false, withStageSelected: true });
          return wrapper.vm.$nextTick().then(() => {
            expect(wrapper.find('.js-add-stage-button').exists()).toBe(true);
          });
        });

        it('displays the tasks by type chart', () => {
          wrapper = createComponent({ shallow: false, withStageSelected: true });
          return wrapper.vm.$nextTick().then(() => {
            expect(wrapper.find('.js-tasks-by-type-chart').exists()).toBe(true);
          });
        });

        it('displays the duration chart', () => {
          displaysDurationChart(true);
        });

        describe('StageTable', () => {
          beforeEach(() => {
            mock = new MockAdapter(axios);
            wrapper = createComponent({
              opts: {
                stubs: {
                  'stage-event-list': true,
                  'add-stage-button': true,
                  'stage-table-header': true,
                },
              },
              shallow: false,
              withStageSelected: true,
            });
          });

          it('has the first stage selected by default', () => {
            const first = selectStageNavItem(0);
            const second = selectStageNavItem(1);

            expect(first.classes('active')).toBe(true);
            expect(second.classes('active')).toBe(false);
          });

          it('can navigate to different stages', () => {
            selectStageNavItem(2).trigger('click');

            return wrapper.vm.$nextTick().then(() => {
              const first = selectStageNavItem(0);
              const third = selectStageNavItem(2);

              expect(third.classes('active')).toBe(true);
              expect(first.classes('active')).toBe(false);
            });
          });
        });
      });

      describe('the user does not have access to the group', () => {
        beforeEach(() => {
          mock = new MockAdapter(axios);
          mock.onAny().reply(403);

          wrapper.vm.onGroupSelect(mockData.group);
          return waitForPromises();
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

        it('does not display the recent activity table', () => {
          displaysRecentActivityCard(false);
        });

        it('does not display the stage table', () => {
          displaysStageTable(false);
        });

        it('does not display the add stage button', () => {
          expect(wrapper.find('.js-add-stage-button').exists()).toBe(false);
        });

        it('does not display the tasks by type chart', () => {
          displaysTypeOfWork(false);
        });

        it('does not display the duration chart', () => {
          displaysDurationChart(false);
        });
      });
    });
  });

  describe('with failed requests while loading', () => {
    const mockRequestCycleAnalyticsData = ({
      overrides = {},
      mockFetchStageData = true,
      mockFetchStageMedian = true,
      mockFetchTasksByTypeData = true,
      mockFetchTopRankedGroupLabels = true,
    }) => {
      const defaultStatus = 200;
      const defaultRequests = {
        fetchGroupStagesAndEvents: {
          status: defaultStatus,
          endpoint: mockData.endpoints.baseStagesEndpoint,
          response: { ...mockData.customizableStagesAndEvents },
        },
        ...overrides,
      };

      if (mockFetchTopRankedGroupLabels) {
        mock
          .onGet(mockData.endpoints.tasksByTypeTopLabelsData)
          .reply(defaultStatus, mockData.groupLabels);
      }

      if (mockFetchTasksByTypeData) {
        mock
          .onGet(mockData.endpoints.tasksByTypeData)
          .reply(defaultStatus, { ...mockData.tasksByTypeData });
      }

      if (mockFetchStageMedian) {
        mock.onGet(mockData.endpoints.stageMedian).reply(defaultStatus, { value: null });
      }

      if (mockFetchStageData) {
        mock.onGet(mockData.endpoints.stageData).reply(defaultStatus, mockData.issueEvents);
      }

      Object.values(defaultRequests).forEach(({ endpoint, status, response }) => {
        mock.onGet(endpoint).replyOnce(status, response);
      });
    };

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

    it('will display an error if the fetchGroupStagesAndEvents request fails', () => {
      expect(findFlashError()).toBeNull();

      mockRequestCycleAnalyticsData({
        overrides: {
          fetchGroupStagesAndEvents: {
            endPoint: mockData.endpoints.baseStagesEndpoint,
            status: httpStatusCodes.NOT_FOUND,
            response: { response: { status: httpStatusCodes.NOT_FOUND } },
          },
        },
      });

      return selectGroupAndFindError('There was an error fetching value stream analytics stages.');
    });

    it('will display an error if the fetchStageData request fails', () => {
      expect(findFlashError()).toBeNull();

      mockRequestCycleAnalyticsData({
        mockFetchStageData: false,
      });

      return selectGroupAndFindError('There was an error fetching data for the selected stage');
    });

    it('will display an error if the fetchTopRankedGroupLabels request fails', () => {
      expect(findFlashError()).toBeNull();

      mockRequestCycleAnalyticsData({ mockFetchTopRankedGroupLabels: false });

      return selectGroupAndFindError(
        'There was an error fetching the top labels for the selected group',
      );
    });

    it('will display an error if the fetchTasksByTypeData request fails', () => {
      expect(findFlashError()).toBeNull();

      mockRequestCycleAnalyticsData({ mockFetchTasksByTypeData: false });

      return selectGroupAndFindError(
        'There was an error fetching data for the tasks by type chart',
      );
    });

    it('will display an error if the fetchStageMedian request fails', () => {
      expect(findFlashError()).toBeNull();

      mockRequestCycleAnalyticsData({
        mockFetchStageMedian: false,
      });

      wrapper.vm.onGroupSelect(mockData.group);

      return waitForPromises().catch(() => {
        expect(findFlashError().innerText.trim()).toEqual(
          'There was an error while fetching value stream analytics data.',
        );
      });
    });
  });

  describe('Url parameters', () => {
    const fakeGroup = {
      id: 2,
      path: 'new-test',
      fullPath: 'new-test-group',
      name: 'New test group',
    };

    beforeEach(() => {
      commonUtils.historyPushState = jest.fn();
      urlUtils.setUrlParams = jest.fn();

      mock = new MockAdapter(axios);

      wrapper = createComponent({
        shallow: false,
        scatterplotEnabled: false,
        stubs: {
          ...defaultStubs,
        },
      });

      return wrapper.vm.$nextTick();
    });

    it('sets the created_after and created_before url parameters', () => {
      return shouldSetUrlParams({
        created_after: toYmd(mockData.startDate),
        created_before: toYmd(mockData.endDate),
        group_id: null,
        'project_ids[]': [],
      });
    });

    describe('with hideGroupDropDown=true', () => {
      beforeEach(() => {
        commonUtils.historyPushState = jest.fn();
        urlUtils.setUrlParams = jest.fn();

        mock = new MockAdapter(axios);

        wrapper = createComponent({
          shallow: false,
          scatterplotEnabled: false,
          stubs: {
            ...defaultStubs,
          },
          props: {
            hideGroupDropDown: true,
          },
        });

        wrapper.vm.$store.dispatch('initializeCycleAnalytics', {
          createdAfter: mockData.startDate,
          createdBefore: mockData.endDate,
          group: fakeGroup,
        });

        return wrapper.vm.$nextTick();
      });

      it('sets the group_id url parameter', () => {
        return shouldSetUrlParams({
          created_after: toYmd(mockData.startDate),
          created_before: toYmd(mockData.endDate),
          group_id: null,
          'project_ids[]': [],
        });
      });
    });

    describe('with a group selected', () => {
      beforeEach(() => {
        wrapper.vm.$store.dispatch('setSelectedGroup', {
          ...fakeGroup,
        });
        return wrapper.vm.$nextTick();
      });

      it('sets the group_id url parameter', () => {
        return shouldSetUrlParams({
          created_after: toYmd(mockData.startDate),
          created_before: toYmd(mockData.endDate),
          group_id: fakeGroup.fullPath,
          'project_ids[]': [],
        });
      });
    });

    describe('with a group and selectedProjectIds set', () => {
      const selectedProjectIds = mockData.selectedProjects.map(({ id }) => id);

      beforeEach(() => {
        wrapper.vm.$store.dispatch('setSelectedGroup', {
          ...selectedGroup,
        });

        wrapper.vm.$store.dispatch('setSelectedProjects', mockData.selectedProjects);

        return wrapper.vm.$nextTick();
      });

      it('sets the project_ids url parameter', () => {
        return shouldSetUrlParams({
          created_after: toYmd(mockData.startDate),
          created_before: toYmd(mockData.endDate),
          group_id: selectedGroup.fullPath,
          'project_ids[]': selectedProjectIds,
        });
      });
    });
  });
});
