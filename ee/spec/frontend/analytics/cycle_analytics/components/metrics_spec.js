import { GlSingleStat } from '@gitlab/ui/dist/charts';
import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import Metrics from 'ee/analytics/cycle_analytics/components/metrics.vue';
import Api from 'ee/api';
import { group } from 'jest/cycle_analytics/mock_data';
import createFlash from '~/flash';
import { timeMetricsData, recentActivityData } from '../mock_data';

jest.mock('~/flash');

describe('Metrics', () => {
  const { full_path: groupPath } = group;
  let wrapper;

  const createComponent = ({ requestParams = {} } = {}) => {
    return shallowMount(Metrics, {
      propsData: {
        groupPath,
        requestParams,
      },
    });
  };

  const findAllMetrics = () => wrapper.findAllComponents(GlSingleStat);

  afterEach(() => {
    wrapper.destroy();
  });

  describe('with successful requests', () => {
    beforeEach(async () => {
      jest.spyOn(Api, 'cycleAnalyticsTimeSummaryData').mockResolvedValue({ data: timeMetricsData });
      jest.spyOn(Api, 'cycleAnalyticsSummaryData').mockResolvedValue({ data: recentActivityData });
      wrapper = createComponent();

      await nextTick;
    });

    it.each(['cycleAnalyticsTimeSummaryData', 'cycleAnalyticsSummaryData'])(
      'fetches data for the %s request',
      (request) => {
        expect(Api[request]).toHaveBeenCalledWith(groupPath, {});
      },
    );

    describe('with additional params', () => {
      beforeEach(async () => {
        wrapper = createComponent({
          requestParams: {
            'project_ids[]': [1],
            created_after: '2020-01-01',
            created_before: '2020-02-01',
          },
        });

        await nextTick;
      });

      it.each(['cycleAnalyticsTimeSummaryData', 'cycleAnalyticsSummaryData'])(
        'sends additional parameters as query paremeters in %s request',
        (request) => {
          expect(Api[request]).toHaveBeenCalledWith(groupPath, {
            'project_ids[]': [1],
            created_after: '2020-01-01',
            created_before: '2020-02-01',
          });
        },
      );
    });

    describe('metrics', () => {
      it.each`
        index | value                          | title                          | unit
        ${0}  | ${timeMetricsData[0].value}    | ${timeMetricsData[0].title}    | ${timeMetricsData[0].unit}
        ${1}  | ${timeMetricsData[1].value}    | ${timeMetricsData[1].title}    | ${timeMetricsData[1].unit}
        ${2}  | ${recentActivityData[0].value} | ${recentActivityData[0].title} | ${recentActivityData[0].unit}
        ${3}  | ${recentActivityData[1].value} | ${recentActivityData[1].title} | ${recentActivityData[1].unit}
        ${4}  | ${recentActivityData[2].value} | ${recentActivityData[2].title} | ${recentActivityData[2].unit}
      `(
        'renders a single stat component for the $title with value and unit',
        ({ index, value, title, unit }) => {
          const metric = findAllMetrics().at(index);
          const expectedUnit = unit ?? '';

          expect(metric.props('value')).toBe(value);
          expect(metric.props('title')).toBe(title);
          expect(metric.props('unit')).toBe(expectedUnit);
        },
      );
    });
  });

  describe.each`
    metric               | failedRequest                      | succesfulRequest
    ${'time summary'}    | ${'cycleAnalyticsTimeSummaryData'} | ${'cycleAnalyticsSummaryData'}
    ${'recent activity'} | ${'cycleAnalyticsSummaryData'}     | ${'cycleAnalyticsTimeSummaryData'}
  `('with the $failedRequest request failing', ({ metric, failedRequest, succesfulRequest }) => {
    beforeEach(async () => {
      jest.spyOn(Api, failedRequest).mockRejectedValue();
      jest.spyOn(Api, succesfulRequest).mockResolvedValue(Promise.resolve({}));
      wrapper = createComponent();

      await wrapper.vm.$nextTick();
    });

    it('it should render a error message', () => {
      expect(createFlash).toHaveBeenCalledWith({
        message: `There was an error while fetching value stream analytics ${metric} data.`,
      });
    });
  });
});
