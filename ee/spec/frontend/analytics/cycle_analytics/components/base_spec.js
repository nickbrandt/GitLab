import { createLocalVue, shallowMount } from '@vue/test-utils';
import Vuex from 'vuex';
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

describe('Cycle Analytics component', () => {
  let wrapper;
  let mock;

  beforeEach(() => {
    mock = new MockAdapter(axios);
    wrapper = shallowMount(localVue.extend(Component), {
      localVue,
      store,
      sync: false,
      propsData: {
        emptyStateSvgPath,
        noDataSvgPath,
        noAccessSvgPath,
      },
    });
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
          wrapper.vm.$store.dispatch('setSelectedGroup', {
            ...mockData.group,
          });

          wrapper.vm.$store.dispatch('receiveCycleAnalyticsDataSuccess', {
            ...mockData.cycleAnalyticsData,
          });

          wrapper.vm.$store.dispatch('receiveStageDataSuccess', {
            events: mockData.issueEvents,
          });
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

        it('displays the stage table', () => {
          expect(wrapper.find(StageTable).exists()).toBe(true);
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
      });
    });
  });
});
