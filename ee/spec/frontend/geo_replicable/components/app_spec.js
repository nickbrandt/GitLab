import Vuex from 'vuex';
import { createLocalVue, shallowMount } from '@vue/test-utils';
import { GlLoadingIcon } from '@gitlab/ui';
import GeoReplicableApp from 'ee/geo_replicable/components/app.vue';
import createStore from 'ee/geo_replicable/store';
import GeoReplicable from 'ee/geo_replicable/components/geo_replicable.vue';
import GeoReplicableEmptyState from 'ee/geo_replicable/components/geo_replicable_empty_state.vue';
import GeoReplicableFilterBar from 'ee/geo_replicable/components/geo_replicable_filter_bar.vue';
import {
  MOCK_GEO_REPLICATION_SVG_PATH,
  MOCK_GEO_TROUBLESHOOTING_LINK,
  MOCK_BASIC_FETCH_DATA_MAP,
  MOCK_REPLICABLE_TYPE,
} from '../mock_data';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('GeoReplicableApp', () => {
  let wrapper;

  const propsData = {
    geoTroubleshootingLink: MOCK_GEO_TROUBLESHOOTING_LINK,
    geoReplicableEmptySvgPath: MOCK_GEO_REPLICATION_SVG_PATH,
  };

  const actionSpies = {
    fetchReplicableItems: jest.fn(),
    setEndpoint: jest.fn(),
  };

  const createComponent = () => {
    wrapper = shallowMount(GeoReplicableApp, {
      localVue,
      store: createStore({ replicableType: MOCK_REPLICABLE_TYPE, useGraphQl: false }),
      propsData,
      methods: {
        ...actionSpies,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  const findGeoReplicableContainer = () => wrapper.find('.geo-replicable-container');
  const findGlLoadingIcon = () => findGeoReplicableContainer().find(GlLoadingIcon);
  const findGeoReplicable = () => findGeoReplicableContainer().find(GeoReplicable);
  const findGeoReplicableEmptyState = () =>
    findGeoReplicableContainer().find(GeoReplicableEmptyState);
  const findGeoReplicableFilterBar = () =>
    findGeoReplicableContainer().find(GeoReplicableFilterBar);

  describe.each`
    isLoading | useGraphQl | replicableItems              | showReplicableItems | showEmptyState | showFilterBar | showLoader
    ${false}  | ${false}   | ${MOCK_BASIC_FETCH_DATA_MAP} | ${true}             | ${false}       | ${true}       | ${false}
    ${false}  | ${false}   | ${[]}                        | ${false}            | ${true}        | ${true}       | ${false}
    ${false}  | ${true}    | ${MOCK_BASIC_FETCH_DATA_MAP} | ${true}             | ${false}       | ${false}      | ${false}
    ${false}  | ${true}    | ${[]}                        | ${false}            | ${true}        | ${false}      | ${false}
    ${true}   | ${false}   | ${MOCK_BASIC_FETCH_DATA_MAP} | ${false}            | ${false}       | ${true}       | ${true}
    ${true}   | ${false}   | ${[]}                        | ${false}            | ${false}       | ${true}       | ${true}
    ${true}   | ${true}    | ${MOCK_BASIC_FETCH_DATA_MAP} | ${false}            | ${false}       | ${false}      | ${true}
    ${true}   | ${true}    | ${[]}                        | ${false}            | ${false}       | ${false}      | ${true}
  `(
    `template`,
    ({
      isLoading,
      useGraphQl,
      replicableItems,
      showReplicableItems,
      showEmptyState,
      showFilterBar,
      showLoader,
    }) => {
      beforeEach(() => {
        createComponent();
      });

      describe(`when isLoading is ${isLoading} and useGraphQl is ${useGraphQl}, ${
        replicableItems.length ? 'with' : 'without'
      } replicableItems`, () => {
        beforeEach(() => {
          wrapper.vm.$store.state.isLoading = isLoading;
          wrapper.vm.$store.state.useGraphQl = useGraphQl;
          wrapper.vm.$store.state.replicableItems = replicableItems;
          wrapper.vm.$store.state.paginationData.total = replicableItems.length;
        });

        it(`${showReplicableItems ? 'shows' : 'hides'} the replicable items`, () => {
          expect(findGeoReplicable().exists()).toBe(showReplicableItems);
        });

        it(`${showEmptyState ? 'shows' : 'hides'} the empty state`, () => {
          expect(findGeoReplicableEmptyState().exists()).toBe(showEmptyState);
        });

        it(`${showFilterBar ? 'shows' : 'hides'} the filter bar`, () => {
          expect(findGeoReplicableFilterBar().exists()).toBe(showFilterBar);
        });

        it(`${showLoader ? 'shows' : 'hides'} the loader`, () => {
          expect(findGlLoadingIcon().exists()).toBe(showLoader);
        });
      });
    },
  );

  describe('onCreate', () => {
    beforeEach(() => {
      createComponent();
    });

    it('calls fetchReplicableItems', () => {
      expect(actionSpies.fetchReplicableItems).toHaveBeenCalled();
    });
  });
});
