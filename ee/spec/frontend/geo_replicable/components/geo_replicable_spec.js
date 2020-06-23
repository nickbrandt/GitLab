import Vuex from 'vuex';
import { createLocalVue, shallowMount } from '@vue/test-utils';
import { GlPagination } from '@gitlab/ui';
import initStore from 'ee/geo_replicable/store';

import * as types from 'ee/geo_replicable/store/mutation_types';
import GeoReplicable from 'ee/geo_replicable/components/geo_replicable.vue';
import GeoReplicableItem from 'ee/geo_replicable/components/geo_replicable_item.vue';
import {
  MOCK_BASIC_FETCH_DATA_MAP,
  MOCK_REPLICABLE_TYPE,
  MOCK_GRAPHQL_PAGINATION_DATA,
  MOCK_RESTFUL_PAGINATION_DATA,
} from '../mock_data';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('GeoReplicable', () => {
  let wrapper;
  let store;

  const createStore = options => {
    store = initStore({ replicableType: MOCK_REPLICABLE_TYPE, useGraphQl: false, ...options });
    jest.spyOn(store, 'dispatch').mockImplementation();
  };

  const createComponent = () => {
    wrapper = shallowMount(GeoReplicable, {
      localVue,
      store,
    });
  };

  afterEach(() => {
    wrapper.destroy();
    store = null;
  });

  const findGeoReplicableContainer = () => wrapper.find('section');
  const findGlPagination = () => findGeoReplicableContainer().find(GlPagination);
  const findGeoReplicableItem = () => findGeoReplicableContainer().findAll(GeoReplicableItem);

  describe('template', () => {
    beforeEach(() => {
      createStore();
      store.commit(types.RECEIVE_REPLICABLE_ITEMS_SUCCESS, {
        data: MOCK_BASIC_FETCH_DATA_MAP,
        pagination: MOCK_RESTFUL_PAGINATION_DATA,
      });
      createComponent();
    });

    it('renders the replicable container', () => {
      expect(findGeoReplicableContainer().exists()).toBe(true);
    });

    describe('GeoReplicableItem', () => {
      it('renders an instance for each replicableItem in the store', () => {
        const replicableItemWrappers = findGeoReplicableItem();
        const replicableItems = [...store.state.replicableItems];

        for (let i = 0; i < replicableItemWrappers.length; i += 1) {
          expect(replicableItemWrappers.at(i).props().projectId).toBe(replicableItems[i].projectId);
        }
      });
    });
  });
  describe('GlPagination', () => {
    describe('when useGraphQl is false', () => {
      it('renders always', () => {
        createStore({ useGraphQl: false });
        createComponent();
        expect(findGlPagination().exists()).toBe(true);
      });
    });

    describe('when useGraphQl is true', () => {
      it('renders always', () => {
        createStore({ useGraphQl: true });
        createComponent();
        expect(findGlPagination().exists()).toBe(true);
      });
    });
  });

  describe.each`
    useGraphQl | currentPage | newPage | action
    ${false}   | ${1}        | ${2}    | ${undefined}
    ${false}   | ${2}        | ${1}    | ${undefined}
    ${true}    | ${1}        | ${2}    | ${'next'}
    ${true}    | ${2}        | ${1}    | ${'prev'}
  `(`changing the page`, ({ useGraphQl, currentPage, newPage, action }) => {
    describe(`when useGraphQl is ${useGraphQl}`, () => {
      describe(`from ${currentPage} to ${newPage}`, () => {
        beforeEach(() => {
          createStore({ useGraphQl });
          store.commit(types.RECEIVE_REPLICABLE_ITEMS_SUCCESS, {
            data: MOCK_BASIC_FETCH_DATA_MAP,
            pagination: { ...MOCK_GRAPHQL_PAGINATION_DATA, page: currentPage },
          });
          createComponent();
          findGlPagination().vm.$emit(GlPagination.model.event, newPage);
        });

        it(`should call setPage with ${newPage}`, () => {
          expect(store.dispatch).toHaveBeenCalledWith('setPage', newPage);
        });

        it(`should call fetchReplicableItems with ${action}`, () => {
          expect(store.dispatch).toHaveBeenCalledWith('fetchReplicableItems', action);
        });
      });
    });
  });
});
