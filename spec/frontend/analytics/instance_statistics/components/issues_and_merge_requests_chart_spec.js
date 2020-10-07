import { createLocalVue, shallowMount } from '@vue/test-utils';
import { GlLineChart } from '@gitlab/ui/dist/charts';
import { useFakeDate } from 'helpers/fake_date';
import VueApollo from 'vue-apollo';
import createMockApollo from 'jest/helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import IssuesAndMergeRequestsChart from '~/analytics/instance_statistics/components/issues_and_merge_requests_chart.vue';
import issuesAndMergeRequestsQuery from '~/analytics/instance_statistics/graphql/queries/issues_and_merge_requests.query.graphql';
import ChartSkeletonLoader from '~/vue_shared/components/resizable_chart/skeleton_loader.vue';
import {
  mockCountsData1,
  mockCountsData2,
  countsMonthlyChartData1,
  countsMonthlyChartData2,
} from '../mock_data';

const localVue = createLocalVue();
localVue.use(VueApollo);

const defaultPageInfo = { hasPreviousPage: false, startCursor: null, endCursor: null };

describe('IssuesAndMergeRequestsChart', () => {
  let wrapper;
  let queryHandler;

  const createComponent = (options = {}) => {
    const {
      loading = false,
      issues = [],
      mergeRequests = [],
      hasNextPage = false,
      secondResponse,
    } = options;
    const apolloQueryResponse = {
      data: {
        issues: { pageInfo: { ...defaultPageInfo, hasNextPage }, nodes: issues },
        mergeRequests: { pageInfo: { ...defaultPageInfo, hasNextPage }, nodes: mergeRequests },
      },
    };
    if (loading) {
      queryHandler = jest.fn().mockReturnValue(new Promise(() => {}));
    } else if (secondResponse) {
      queryHandler = jest
        .fn()
        .mockResolvedValueOnce(apolloQueryResponse)
        .mockResolvedValueOnce(secondResponse);
    } else {
      queryHandler = jest.fn().mockResolvedValue(apolloQueryResponse);
    }

    const apolloProvider = createMockApollo([[issuesAndMergeRequestsQuery, queryHandler]]);

    return shallowMount(IssuesAndMergeRequestsChart, {
      localVue,
      apolloProvider,
      props: {
        startDate: useFakeDate(2020, 9, 26),
        endDate: useFakeDate(2020, 10, 1),
        totalDataPoints: 200,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  const findLoader = () => wrapper.find(ChartSkeletonLoader);
  const findChart = () => wrapper.find(GlLineChart);
  const findFlashError = () => document.querySelector('.flash-container .flash-text');
  const findError = async msg => {
    await waitForPromises();
    expect(findFlashError().innerText.trim()).toEqual(msg);
  };

  describe('while loading', () => {
    beforeEach(() => {
      wrapper = createComponent({ loading: true });
    });

    it('requests data', () => {
      expect(queryHandler).toBeCalledTimes(1);
    });

    it('displays the skeleton loader', () => {
      expect(findLoader().exists()).toBe(true);
    });

    it('hides the chart', () => {
      expect(findChart().exists()).toBe(false);
    });

    it('does not show an error', async () => {
      expect(await findFlashError()).toBeNull();
    });
  });

  describe('with data', () => {
    beforeEach(() => {
      wrapper = createComponent({ issues: mockCountsData1, mergeRequests: mockCountsData2 });
    });

    it('requests data', () => {
      expect(queryHandler).toBeCalledTimes(1);
    });

    it('hides the skeleton loader', () => {
      expect(findLoader().exists()).toBe(false);
    });

    it('renders the chart', () => {
      expect(findChart().exists()).toBe(true);
    });

    it('passes the data to the line chart', () => {
      expect(findChart().props('data')).toEqual([
        { data: countsMonthlyChartData1, name: 'Issues' },
        { data: countsMonthlyChartData2, name: 'Merge Requests' },
      ]);
    });

    it('does not show an error', async () => {
      expect(await findFlashError()).toBeNull();
    });
  });

  describe('when fetching more data', () => {
    describe('when the fetchMore query returns data', () => {
      beforeEach(async () => {
        const newData = { recordedAt: '2020-07-21', count: 5 };
        wrapper = createComponent({
          issues: mockCountsData1,
          mergeRequests: mockCountsData2,
          hasNextPage: true,
          secondResponse: {
            data: {
              issues: { pageInfo: { ...defaultPageInfo, hasNextPage: false }, nodes: [newData] },
              mergeRequests: {
                pageInfo: { ...defaultPageInfo, hasNextPage: false },
                nodes: [newData],
              },
            },
          },
        });

        jest.spyOn(wrapper.vm.$apollo.queries.issuesAndMergeRequests, 'fetchMore');
        await wrapper.vm.$nextTick();
      });

      it('requests data twice', () => {
        expect(queryHandler).toBeCalledTimes(2);
      });

      it('calls fetchMore', async () => {
        expect(wrapper.vm.$apollo.queries.issuesAndMergeRequests.fetchMore).toHaveBeenCalledTimes(
          1,
        );
      });

      it('passes the data to the line chart', async () => {
        const [[issuesDate], ...remainingIssues] = countsMonthlyChartData1;
        const [[mergeRequestDate], ...remainingMergeRequests] = countsMonthlyChartData2;
        expect(findChart().props('data')).toEqual([
          { data: [[issuesDate, 32], ...remainingIssues], name: 'Issues' },
          { data: [[mergeRequestDate, 8], ...remainingMergeRequests], name: 'Merge Requests' },
        ]);
      });
    });

    describe('when the fetchMore query throws an error', () => {
      beforeEach(async () => {
        setFixtures('<div class="flash-container"></div>');
        wrapper = createComponent({
          issues: mockCountsData1,
          mergeRequests: mockCountsData2,
          hasNextPage: true,
        });
        jest
          .spyOn(wrapper.vm.$apollo.queries.issuesAndMergeRequests, 'fetchMore')
          .mockImplementation(jest.fn().mockRejectedValue());
        await wrapper.vm.$nextTick();
      });

      it('calls fetchMore', async () => {
        expect(wrapper.vm.$apollo.queries.issuesAndMergeRequests.fetchMore).toHaveBeenCalledTimes(
          1,
        );
      });

      it('show an error message', async () => {
        await findError(
          'Could not load the issues and merge requests chart. Please refresh the page to try again.',
        );
      });
    });
  });
});
