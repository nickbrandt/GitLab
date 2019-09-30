import { createLocalVue, shallowMount, mount } from '@vue/test-utils';
import Vuex from 'vuex';
import Vue from 'vue';
import store from 'ee/analytics/cycle_analytics/store';
import Component from 'ee/analytics/cycle_analytics/components/base.vue';
import { GlEmptyState } from '@gitlab/ui';
import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import GroupsDropdownFilter from 'ee/analytics/shared/components/groups_dropdown_filter.vue';
import ProjectsDropdownFilter from 'ee/analytics/shared/components/projects_dropdown_filter.vue';
import DateRangeDropdown from 'ee/analytics/shared/components/date_range_dropdown.vue';
import SummaryTable from 'ee/analytics/cycle_analytics/components/summary_table.vue';
import StageTable from 'ee/analytics/cycle_analytics/components/stage_table.vue';
import 'bootstrap';
import '~/gl_dropdown';
import * as mockData from '../mock_data';

const noDataSvgPath = 'path/to/no/data';
const noAccessSvgPath = 'path/to/no/access';
const emptyStateSvgPath = 'path/to/empty/state';

const localVue = createLocalVue();
localVue.use(Vuex);

function createComponent({ opts = {}, shallow = true, withStageSelected = false } = {}) {
  const func = shallow ? shallowMount : mount;
  const comp = func(Component, {
    localVue,
    store,
    sync: false,
    propsData: {
      emptyStateSvgPath,
      noDataSvgPath,
      noAccessSvgPath,
    },
    ...opts,
  });

  if (withStageSelected) {
    comp.vm.$store.dispatch('setSelectedGroup', {
      ...mockData.group,
    });

    comp.vm.$store.dispatch('receiveCycleAnalyticsDataSuccess', {
      ...mockData.cycleAnalyticsData,
    });

    comp.vm.$store.dispatch('receiveStageDataSuccess', {
      events: mockData.issueEvents,
    });
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

  beforeEach(() => {
    mock = new MockAdapter(axios);
    wrapper = createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
    mock.restore();
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
      });

      it('does not display the projects or timeframe filters', () => {
        expect(wrapper.find(ProjectsDropdownFilter).exists()).toBe(false);
        expect(wrapper.find(DateRangeDropdown).exists()).toBe(false);
      });
    });

    describe('after a filter has been selected', () => {
      describe('the user has access to the group', () => {
        beforeEach(() => {
          wrapper = createComponent({ withStageSelected: true });
        });

        it('hides the empty state', () => {
          expect(wrapper.find(GlEmptyState).exists()).toBe(false);
        });

        it('displays the projects and timeframe filters', () => {
          expect(wrapper.find(ProjectsDropdownFilter).exists()).toBe(true);
          expect(wrapper.find(DateRangeDropdown).exists()).toBe(true);
        });

        it('displays summary table', () => {
          expect(wrapper.find(SummaryTable).exists()).toBe(true);
        });

        it('does not display the add stage button', () => {
          expect(wrapper.find('.js-add-stage-button').exists()).toBe(false);
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
            });
          });

          afterEach(() => {
            wrapper.destroy();
            mock.restore();
          });

          it('displays the stage table', () => {
            expect(wrapper.find(StageTable).exists()).toBe(true);
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

        it('will not render the summary table', () => {
          expect(wrapper.find('.js-summary-table').exists()).toBe(false);
        });

        it('will not render the stage table', () => {
          expect(wrapper.find('.js-stage-table').exists()).toBe(false);
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
              stubs: {
                'summary-table': true,
                'stage-event-list': true,
                'stage-nav-item': true,
              },
              provide: {
                glFeatures: {
                  customizableCycleAnalytics: true,
                },
              },
            },
            shallow: false,
            withStageSelected: true,
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
    });
  });
});
