import { createLocalVue, shallowMount } from '@vue/test-utils';
import Vuex from 'vuex';
import ProductivityApp from 'ee/analytics/productivity_analytics/components/app.vue';
import MergeRequestTable from 'ee/analytics/productivity_analytics/components/mr_table.vue';
import store from 'ee/analytics/productivity_analytics/store';
import { chartKeys } from 'ee/analytics/productivity_analytics/constants';
import { TEST_HOST } from 'helpers/test_constants';
import { GlEmptyState, GlLoadingIcon, GlDropdown, GlDropdownItem, GlButton } from '@gitlab/ui';
import { GlColumnChart } from '@gitlab/ui/dist/charts';
import resetStore from '../helpers';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('ProductivityApp component', () => {
  let wrapper;

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

  beforeEach(() => {
    wrapper = shallowMount(localVue.extend(ProductivityApp), {
      localVue,
      store,
      sync: false,
      propsData,
      methods: {
        ...actionSpies,
      },
    });

    jest.spyOn(store, 'dispatch').mockImplementation();
  });

  afterEach(() => {
    wrapper.destroy();
    resetStore(store);
  });

  const findTimeToMergeSection = () => wrapper.find('.qa-time-to-merge');
  const findMrTableSortSection = () => wrapper.find('.qa-mr-table-sort');
  const findMrTableSection = () => wrapper.find('.qa-mr-table');
  const findMrTable = () => findMrTableSection().find(MergeRequestTable);
  const findSortFieldDropdown = () => findMrTableSortSection().find(GlDropdown);
  const findSortOrderToggle = () => findMrTableSortSection().find(GlButton);
  const findTimeBasedSection = () => wrapper.find('.qa-time-based');
  const findCommitBasedSection = () => wrapper.find('.qa-commit-based');

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
        store.state.filters.groupNamespace = 'gitlab-org';
      });

      describe('and user has no access to the group', () => {
        beforeEach(() => {
          store.state.charts.charts[chartKeys.main].hasError = 403;
        });

        it('renders the no access illustration', () => {
          const emptyState = wrapper.find(GlEmptyState);
          expect(emptyState.exists()).toBe(true);

          expect(emptyState.props('svgPath')).toBe(propsData.noAccessSvgPath);
        });
      });

      describe('and user has access to the group', () => {
        beforeEach(() => {
          store.state.charts.charts[chartKeys.main].hasError = false;
        });

        describe('Time to merge chart', () => {
          it('renders the title', () => {
            expect(findTimeToMergeSection().text()).toContain('Time to merge');
          });

          describe('when chart is loading', () => {
            beforeEach(() => {
              store.state.charts.charts[chartKeys.main].isLoading = true;
            });

            it('renders a loading indicator', () => {
              expect(
                findTimeToMergeSection()
                  .find(GlLoadingIcon)
                  .exists(),
              ).toBe(true);
            });
          });

          describe('when chart finished loading', () => {
            beforeEach(() => {
              store.state.charts.charts[chartKeys.main].isLoading = false;
            });

            describe('and the chart has data', () => {
              beforeEach(() => {
                store.state.charts.charts[chartKeys.main].data = { 1: 2, 2: 3 };
              });

              it('renders a column chart', () => {
                expect(
                  findTimeToMergeSection()
                    .find(GlColumnChart)
                    .exists(),
                ).toBe(true);
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

                  findTimeToMergeSection()
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
            });

            describe("and the chart doesn't have any data", () => {
              beforeEach(() => {
                store.state.charts.charts[chartKeys.main].data = null;
              });

              it('renders a "no data" message', () => {
                expect(findTimeToMergeSection().text()).toContain(
                  'There is no data available. Please change your selection.',
                );
              });
            });
          });
        });

        describe('Time based histogram', () => {
          beforeEach(() => {
            store.state.charts.charts[chartKeys.main].isLoading = false;
            store.state.charts.charts[chartKeys.main].data = { 1: 2, 2: 3 };
          });

          describe('when chart is loading', () => {
            beforeEach(() => {
              store.state.charts.charts[chartKeys.timeBasedHistogram].isLoading = true;
            });

            it('renders a loading indicator', () => {
              expect(
                findTimeBasedSection()
                  .find(GlLoadingIcon)
                  .exists(),
              ).toBe(true);
            });
          });

          describe('when chart finished loading', () => {
            beforeEach(() => {
              store.state.charts.charts[chartKeys.timeBasedHistogram].isLoading = false;
            });

            describe('and the chart has data', () => {
              beforeEach(() => {
                store.state.charts.charts[chartKeys.timeBasedHistogram].data = { 1: 2, 2: 3 };
              });

              it('renders a metric type dropdown', () => {
                expect(
                  findTimeBasedSection()
                    .find(GlDropdown)
                    .exists(),
                ).toBe(true);
              });

              it('should change the metric type', () => {
                findTimeBasedSection()
                  .findAll(GlDropdownItem)
                  .at(0)
                  .vm.$emit('click');

                expect(actionSpies.setMetricType).toHaveBeenCalledWith({
                  metricType: 'time_to_first_comment',
                  chartKey: chartKeys.timeBasedHistogram,
                });
              });

              it('renders a column chart', () => {
                expect(
                  findTimeBasedSection()
                    .find(GlColumnChart)
                    .exists(),
                ).toBe(true);
              });
            });

            describe("and the chart doesn't have any data", () => {
              beforeEach(() => {
                store.state.charts.charts[chartKeys.timeBasedHistogram].data = null;
              });

              it('renders a "no data" message', () => {
                expect(findTimeBasedSection().text()).toContain(
                  'There is no data for the selected metric. Please change your selection.',
                );
              });
            });
          });
        });

        describe('Commit based histogram', () => {
          beforeEach(() => {
            store.state.charts.charts[chartKeys.main].isLoading = false;
            store.state.charts.charts[chartKeys.main].data = { 1: 2, 2: 3 };
          });

          describe('when chart is loading', () => {
            beforeEach(() => {
              store.state.charts.charts[chartKeys.commitBasedHistogram].isLoading = true;
            });

            it('renders a loading indicator', () => {
              expect(
                findCommitBasedSection()
                  .find(GlLoadingIcon)
                  .exists(),
              ).toBe(true);
            });
          });

          describe('when chart finished loading', () => {
            beforeEach(() => {
              store.state.charts.charts[chartKeys.commitBasedHistogram].isLoading = false;
            });

            describe('and the chart has data', () => {
              beforeEach(() => {
                store.state.charts.charts[chartKeys.commitBasedHistogram].data = { 1: 2, 2: 3 };
              });

              it('renders a metric type dropdown', () => {
                expect(
                  findCommitBasedSection()
                    .find(GlDropdown)
                    .exists(),
                ).toBe(true);
              });

              it('should change the metric type', () => {
                findCommitBasedSection()
                  .findAll(GlDropdownItem)
                  .at(0)
                  .vm.$emit('click');

                expect(actionSpies.setMetricType).toHaveBeenCalledWith({
                  metricType: 'commits_count',
                  chartKey: chartKeys.commitBasedHistogram,
                });
              });

              it('renders a column chart', () => {
                expect(
                  findCommitBasedSection()
                    .find(GlColumnChart)
                    .exists(),
                ).toBe(true);
              });
            });

            describe("and the chart doesn't have any data", () => {
              beforeEach(() => {
                store.state.charts.charts[chartKeys.commitBasedHistogram].data = null;
              });

              it('renders a "no data" message', () => {
                expect(findTimeBasedSection().text()).toContain(
                  'There is no data for the selected metric. Please change your selection.',
                );
              });
            });
          });
        });

        describe('MR table', () => {
          beforeEach(() => {
            store.state.charts.charts[chartKeys.main].isLoading = false;
            store.state.charts.charts[chartKeys.main].data = { 1: 2, 2: 3 };
          });

          describe('when table is loading', () => {
            beforeEach(() => {
              store.state.table.isLoadingTable = true;
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
            beforeEach(() => {
              store.state.table.isLoadingTable = false;
            });

            describe('and the table has data', () => {
              beforeEach(() => {
                store.state.table.mergeRequests = [{ id: 1, title: 'This is a test MR' }];
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
                expect(actionSpies.setColumnMetric).toHaveBeenCalledWith('time_to_first_comment');
              });

              it('should change the page', () => {
                const page = 2;
                findMrTable().vm.$emit('pageChange', page);
                expect(actionSpies.setMergeRequestsPage).toHaveBeenCalledWith(page);
              });

              describe('and there are merge requests available', () => {
                beforeEach(() => {
                  store.state.table.mergeRequests = [{ id: 1 }];
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
            });

            describe("and the table doesn't have any data", () => {
              beforeEach(() => {
                store.state.table.mergeRequests = [];
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
    });
  });
});
