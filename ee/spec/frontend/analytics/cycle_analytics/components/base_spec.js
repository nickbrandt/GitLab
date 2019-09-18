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
import { TEST_HOST } from 'helpers/test_constants';
import 'bootstrap';
import '~/gl_dropdown';
import * as mockData from '../mock_data';

const noDataSvgPath = 'path/to/no/data';
const noAccessSvgPath = 'path/to/no/access';
const localVue = createLocalVue();
localVue.use(Vuex);

describe('Cycle Analytics component', () => {
  const emptyStateSvgPath = `${TEST_HOST}/images/home/nasa.svg`;
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
        expect(wrapper.find(GlEmptyState).exists()).toBe(true);
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
  });
});
