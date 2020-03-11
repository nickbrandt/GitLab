import Vue from 'vue';
import { createLocalVue, shallowMount } from '@vue/test-utils';
import Vuex from 'vuex';
import store from 'ee/analytics/cycle_analytics/store';
import UrlSyncMixin from 'ee/analytics/cycle_analytics/mixins/url_sync_mixin';
import { toYmd } from 'ee/analytics/shared/utils';
import { startDate, endDate } from '../mock_data';

const localVue = createLocalVue();
localVue.use(Vuex);

const createComponent = () => {
  const Component = Vue.extend({
    localVue,
    store,
    mixins: [UrlSyncMixin],
    render(h) {
      return h('div');
    },
  });

  return shallowMount(Component);
};

describe('UrlSyncMixin', () => {
  let wrapper;
  beforeEach(() => {
    wrapper = createComponent();
    wrapper.vm.$store.dispatch('initializeCycleAnalytics', {
      createdAfter: startDate,
      createdBefore: endDate,
    });
  });

  afterEach(() => {
    wrapper.vm.$destroy();
  });

  describe('watch', () => {
    describe('query', () => {
      const defaultState = {
        group_id: null,
        'project_ids[]': [],
        created_after: toYmd(startDate),
        created_before: toYmd(endDate),
      };

      it('sets the start and end date to the default state values', () => {
        expect(wrapper.vm.query).toEqual(defaultState);
      });

      it.each`
        param               | action                   | payload                                                  | updatedParams
        ${'group_id'}       | ${'setSelectedGroup'}    | ${{ fullPath: 'test-group', name: 'test group' }}        | ${{ group_id: 'test-group' }}
        ${'project_ids'}    | ${'setSelectedProjects'} | ${[{ id: 1 }, { id: 2 }]}                                | ${{ 'project_ids[]': [1, 2] }}
        ${'created_after'}  | ${'setDateRange'}        | ${{ startDate: '2020-06-18', endDate, skipFetch: true }} | ${{ created_after: toYmd('2020-06-18') }}
        ${'created_before'} | ${'setDateRange'}        | ${{ endDate: '2020-06-18', startDate, skipFetch: true }} | ${{ created_before: toYmd('2020-06-18') }}
      `(
        'sets the $param parameter when $action is dispatched',
        ({ action, payload, updatedParams }) => {
          wrapper.vm.$store.dispatch(action, payload);

          expect(wrapper.vm.query).toEqual({
            ...defaultState,
            ...updatedParams,
          });
        },
      );
    });
  });
});
