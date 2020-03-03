import Vuex from 'vuex';
import { createLocalVue, shallowMount } from '@vue/test-utils';
import { GlLoadingIcon } from '@gitlab/ui';
import GeoReplicableApp from 'ee/geo_replicable/components/app.vue';
import createStore from 'ee/geo_replicable/store';
import GeoReplicable from 'ee/geo_replicable/components/geo_replicable.vue';
import GeoReplicableEmptyState from 'ee/geo_replicable/components/geo_replicable_empty_state.vue';
import GeoReplicableFilterBar from 'ee/geo_replicable/components/geo_replicable_filter_bar.vue';
import {
  MOCK_GEO_SVG_PATH,
  MOCK_ISSUES_SVG_PATH,
  MOCK_GEO_TROUBLESHOOTING_LINK,
  MOCK_BASIC_FETCH_DATA_MAP,
  MOCK_REPLICABLE_TYPE,
} from '../mock_data';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('GeoReplicableApp', () => {
  let wrapper;

  const propsData = {
    geoSvgPath: MOCK_GEO_SVG_PATH,
    issuesSvgPath: MOCK_ISSUES_SVG_PATH,
    geoTroubleshootingLink: MOCK_GEO_TROUBLESHOOTING_LINK,
  };

  const actionSpies = {
    fetchReplicableItems: jest.fn(),
    setEndpoint: jest.fn(),
  };

  const createComponent = () => {
    wrapper = shallowMount(GeoReplicableApp, {
      localVue,
      store: createStore(MOCK_REPLICABLE_TYPE),
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

  describe('template', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the replicable container', () => {
      expect(findGeoReplicableContainer().exists()).toBe(true);
    });

    it('renders the filter bar', () => {
      expect(findGeoReplicableFilterBar().exists()).toBe(true);
    });

    describe('when isLoading = true', () => {
      beforeEach(() => {
        wrapper.vm.$store.state.isLoading = true;
      });

      it('hides replicable items', () => {
        expect(findGeoReplicable().exists()).toBe(false);
      });

      it('hides empty state', () => {
        expect(findGeoReplicableEmptyState().exists()).toBe(false);
      });

      it('shows loader', () => {
        expect(findGlLoadingIcon().exists()).toBe(true);
      });
    });

    describe('when isLoading = false', () => {
      beforeEach(() => {
        wrapper.vm.$store.state.isLoading = false;
      });

      describe('with data', () => {
        beforeEach(() => {
          wrapper.vm.$store.state.replicableItems = MOCK_BASIC_FETCH_DATA_MAP.data;
          wrapper.vm.$store.state.totalReplicableItems = MOCK_BASIC_FETCH_DATA_MAP.total;
        });

        it('shows replicable items', () => {
          expect(findGeoReplicable().exists()).toBe(true);
        });

        it('hides empty state', () => {
          expect(findGeoReplicableEmptyState().exists()).toBe(false);
        });

        it('hides loader', () => {
          expect(findGlLoadingIcon().exists()).toBe(false);
        });
      });

      describe('with no replicable items', () => {
        beforeEach(() => {
          wrapper.vm.$store.state.replicableItems = [];
          wrapper.vm.$store.state.totalReplicableItems = 0;
        });

        it('hides replicable items', () => {
          expect(findGeoReplicable().exists()).toBe(false);
        });

        it('shows empty state', () => {
          expect(findGeoReplicableEmptyState().exists()).toBe(true);
        });

        it('hides loader', () => {
          expect(findGlLoadingIcon().exists()).toBe(false);
        });
      });
    });
  });

  describe('onCreate', () => {
    beforeEach(() => {
      createComponent();
    });

    it('calls fetchReplicableItems', () => {
      expect(actionSpies.fetchReplicableItems).toHaveBeenCalled();
    });
  });
});
