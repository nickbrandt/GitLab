import { createLocalVue, shallowMount } from '@vue/test-utils';
import Vuex from 'vuex';
import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import ProductivityApp from 'ee/analytics/productivity_analytics/components/app.vue';
import MergeRequestTable from 'ee/analytics/productivity_analytics/components/mr_table.vue';
import store from 'ee/analytics/productivity_analytics/store';
import { chartKeys } from 'ee/analytics/productivity_analytics/constants';
import { TEST_HOST } from 'helpers/test_constants';
import { GlEmptyState, GlLoadingIcon, GlDropdown, GlDropdownItem, GlButton } from '@gitlab/ui';
import { GlColumnChart } from '@gitlab/ui/dist/charts';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('ProductivityApp component', () => {
  let wrapper;
  let mock;

  const propsData = {
    endpoint: TEST_HOST,
    emptyStateSvgPath: TEST_HOST,
    noAccessSvgPath: TEST_HOST,
  };

  const actionSpies = {
    setMetricType: jest.fn(),
    chartItemClicked: jest.fn(),
    setSortField: jest.fn(),
    setMergeRequestsPage: jest.fn(),
    toggleSortOrder: jest.fn(),
    setColumnMetric: jest.fn(),
  };

  const mainChartData = { 1: 2, 2: 3 };

  beforeEach(() => {
    mock = new MockAdapter(axios);
    wrapper = shallowMount(localVue.extend(ProductivityApp), {
      localVue,
      store,
      sync: false,
      propsData,
      methods: {
        ...actionSpies,
      },
    });
  });

  afterEach(() => {
    wrapper.destroy();
    mock.restore();
  });

  const findMainMetricChart = () => wrapper.find({ ref: 'mainChart' });
  const findSecondaryChartsSection = () => wrapper.find({ ref: 'secondaryCharts' });
  const findTimeBasedMetricChart = () => wrapper.find({ ref: 'timeBasedChart' });
  const findCommitBasedMetricChart = () => wrapper.find({ ref: 'commitBasedChart' });
  const findMrTableSortSection = () => wrapper.find('.js-mr-table-sort');
  const findSortFieldDropdown = () => findMrTableSortSection().find(GlDropdown);
  const findSortOrderToggle = () => findMrTableSortSection().find(GlButton);
  const findMrTableSection = () => wrapper.find('.js-mr-table');
  const findMrTable = () => findMrTableSection().find(MergeRequestTable);

  describe('template', () => {
    describe('without a group being selected', () => {
      it('renders the empty state illustration', () => {
        const emptyState = wrapper.find(GlEmptyState);
        expect(emptyState.exists()).toBe(true);

        expect(emptyState.props('svgPath')).toBe(propsData.emptyStateSvgPath);
      });
    });

    describe('with a group being selected', () => {
      beforeEach(() => {
        wrapper.vm.$store.dispatch('filters/setGroupNamespace', 'gitlab-org');
        mock.onGet(wrapper.vm.$store.state.endpoint).replyOnce(200);
      });

      describe('user has no access to the group', () => {
        beforeEach(() => {
          const error = { response: { status: 403 } };
          wrapper.vm.$store.dispatch('charts/receiveChartDataError', {
            chartKey: chartKeys.main,
            error,
          });
          wrapper.vm.$store.state.charts.charts[chartKeys.main].errorCode = 403;
        });

        it('renders the no access illustration', () => {
          const emptyState = wrapper.find(GlEmptyState);
          expect(emptyState.exists()).toBe(true);

          expect(emptyState.props('svgPath')).toBe(propsData.noAccessSvgPath);
        });
      });

      describe('user has access to the group', () => {
        beforeEach(() => {
          wrapper.vm.$store.state.charts.charts[chartKeys.main].errorCode = null;
        });

        describe('when the main chart is loading', () => {
          beforeEach(() => {
            wrapper.vm.$store.dispatch('charts/requestChartData', chartKeys.main);
          });

          it('renders a metric chart component for the main chart', () => {
            expect(findMainMetricChart().exists()).toBe(true);
          });

          it('sets isLoading=true on the metric chart', () => {
            expect(findMainMetricChart().props('isLoading')).toBe(true);
          });

          it('does not render any other charts', () => {
            expect(findSecondaryChartsSection().exists()).toBe(false);
          });

          it('does not render the MR table', () => {
            expect(findMrTableSortSection().exists()).toBe(false);
            expect(findMrTableSection().exists()).toBe(false);
          });
        });

        describe('when the main chart finished loading', () => {
          describe('and has data', () => {
            beforeEach(() => {
              wrapper.vm.$store.dispatch('charts/receiveChartDataSuccess', {
                chartKey: chartKeys.main,
                data: mainChartData,
              });
            });

            it('sets isLoading=false on the metric chart', () => {
              expect(findMainMetricChart().props('isLoading')).toBe(false);
            });

            it('passes non-empty chartData to the metric chart', () => {
              expect(findMainMetricChart().props('chartData')).not.toEqual([]);
            });

            describe('when an item on the chart is clicked', () => {
              beforeEach(() => {
                const data = {
                  chart: null,
                  params: {
                    data: {
                      value: [0, 1],
                    },
                  },
                };

                findMainMetricChart()
                  .find(GlColumnChart)
                  .vm.$emit('chartItemClicked', data);
              });

              it('dispatches chartItemClicked action', () => {
                expect(actionSpies.chartItemClicked).toHaveBeenCalledWith({
                  chartKey: chartKeys.main,
                  item: 0,
                });
              });

              it('dispatches setMergeRequestsPage action', () => {
                expect(actionSpies.setMergeRequestsPage).toHaveBeenCalledWith(0);
              });
            });

            describe('Time based histogram', () => {
              it('renders a metric chart component', () => {
                expect(findTimeBasedMetricChart().exists()).toBe(true);
              });

              describe('when chart finished loading', () => {
                describe('and the chart has data', () => {
                  beforeEach(() => {
                    wrapper.vm.$store.dispatch('charts/receiveChartDataSuccess', {
                      chartKey: chartKeys.timeBasedHistogram,
                      data: { 1: 2, 2: 3 },
                    });
                  });

                  it('sets isLoading=false on the metric chart', () => {
                    expect(findTimeBasedMetricChart().props('isLoading')).toBe(false);
                  });

                  it('passes non-empty chartData to the metric chart', () => {
                    expect(findTimeBasedMetricChart().props('chartData')).not.toEqual([]);
                  });

                  it('should call setMetricType  when `metricTypeChange` is emitted on the metric chart', () => {
                    findTimeBasedMetricChart().vm.$emit('metricTypeChange', 'time_to_merge');

                    expect(actionSpies.setMetricType).toHaveBeenCalledWith({
                      metricType: 'time_to_merge',
                      chartKey: chartKeys.timeBasedHistogram,
                    });
                  });
                });
              });
            });

            describe('Commit based histogram', () => {
              it('renders a metric chart component', () => {
                expect(findCommitBasedMetricChart().exists()).toBe(true);
              });

              describe('when chart finished loading', () => {
                describe('and the chart has data', () => {
                  beforeEach(() => {
                    wrapper.vm.$store.dispatch('charts/receiveChartDataSuccess', {
                      chartKey: chartKeys.commitBasedHistogram,
                      data: { 1: 2, 2: 3 },
                    });
                  });

                  it('sets isLoading=false on the metric chart', () => {
                    expect(findCommitBasedMetricChart().props('isLoading')).toBe(false);
                  });

                  it('passes non-empty chartData to the metric chart', () => {
                    expect(findCommitBasedMetricChart().props('chartData')).not.toEqual([]);
                  });

                  describe('when the user changes the metric', () => {
                    beforeEach(() => {
                      findCommitBasedMetricChart().vm.$emit('metricTypeChange', 'loc_per_commit');
                    });

                    it('should call setMetricType  when `metricTypeChange` is emitted on the metric chart', () => {
                      expect(actionSpies.setMetricType).toHaveBeenCalledWith({
                        metricType: 'loc_per_commit',
                        chartKey: chartKeys.commitBasedHistogram,
                      });
                    });

                    it("should update the chart's x axis label", () => {
                      const columnChart = findCommitBasedMetricChart().find(GlColumnChart);
                      expect(columnChart.props('xAxisTitle')).toBe('Number of commits per MR');
                    });
                  });
                });
              });
            });

            describe('MR table', () => {
              describe('when table is loading', () => {
                beforeEach(() => {
                  wrapper.vm.$store.dispatch('table/requestMergeRequests');
                });

                it('renders a loading indicator', () => {
                  expect(
                    findMrTableSection()
                      .find(GlLoadingIcon)
                      .exists(),
                  ).toBe(true);
                });
              });

              describe('when table finished loading', () => {
                describe('and the table has data', () => {
                  beforeEach(() => {
                    wrapper.vm.$store.dispatch('table/receiveMergeRequestsSuccess', {
                      headers: {},
                      data: [{ id: 1, title: 'This is a test MR' }],
                    });
                  });

                  it('renders the MR table', () => {
                    expect(findMrTable().exists()).toBe(true);
                  });

                  it('doesn’t render a "no data" message', () => {
                    expect(
                      findMrTableSection()
                        .find('.js-no-data')
                        .exists(),
                    ).toBe(false);
                  });

                  it('should change the column metric', () => {
                    findMrTable().vm.$emit('columnMetricChange', 'time_to_first_comment');
                    expect(actionSpies.setColumnMetric).toHaveBeenCalledWith(
                      'time_to_first_comment',
                    );
                  });

                  it('should change the page', () => {
                    const page = 2;
                    findMrTable().vm.$emit('pageChange', page);
                    expect(actionSpies.setMergeRequestsPage).toHaveBeenCalledWith(page);
                  });

                  describe('sort controls', () => {
                    it('renders the sort dropdown and button', () => {
                      expect(findSortFieldDropdown().exists()).toBe(true);
                      expect(findSortOrderToggle().exists()).toBe(true);
                    });

                    it('should change the sort field', () => {
                      findSortFieldDropdown()
                        .findAll(GlDropdownItem)
                        .at(0)
                        .vm.$emit('click');

                      expect(actionSpies.setSortField).toHaveBeenCalled();
                    });

                    it('should toggle the sort order', () => {
                      findSortOrderToggle().vm.$emit('click');
                      expect(actionSpies.toggleSortOrder).toHaveBeenCalled();
                    });
                  });
                });

                describe("and the table doesn't have any data", () => {
                  beforeEach(() => {
                    wrapper.vm.$store.dispatch('table/receiveMergeRequestsSuccess', {
                      headers: {},
                      data: [],
                    });
                  });

                  it('renders a "no data" message', () => {
                    expect(
                      findMrTableSection()
                        .find('.js-no-data')
                        .exists(),
                    ).toBe(true);
                  });

                  it('doesn`t render the MR table', () => {
                    expect(findMrTable().exists()).not.toBe(true);
                  });

                  it('doesn`t render the sort dropdown and button', () => {
                    expect(findSortFieldDropdown().exists()).not.toBe(true);
                    expect(findSortOrderToggle().exists()).not.toBe(true);
                  });
                });
              });
            });
          });

          describe('and has no data', () => {
            beforeEach(() => {
              wrapper.vm.$store.dispatch('charts/receiveChartDataSuccess', {
                chartKey: chartKeys.main,
                data: {},
              });
            });

            it('sets isLoading=false on the metric chart', () => {
              expect(findMainMetricChart().props('isLoading')).toBe(false);
            });

            it('passes an empty array as chartData to the metric chart', () => {
              expect(findMainMetricChart().props('chartData')).toEqual([]);
            });

            it('does not render any other charts', () => {
              expect(findSecondaryChartsSection().exists()).toBe(false);
            });

            it('does not render the MR table', () => {
              expect(findMrTableSortSection().exists()).toBe(false);
              expect(findMrTableSection().exists()).toBe(false);
            });
          });
        });
      });
    });
  });
});
