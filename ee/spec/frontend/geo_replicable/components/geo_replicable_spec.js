import Vuex from 'vuex';
import { createLocalVue, mount } from '@vue/test-utils';
import { GlPagination } from '@gitlab/ui';
import createStore from 'ee/geo_replicable/store';
import GeoReplicable from 'ee/geo_replicable/components/geo_replicable.vue';
import GeoReplicableItem from 'ee/geo_replicable/components/geo_replicable_item.vue';
import { MOCK_BASIC_FETCH_DATA_MAP, MOCK_REPLICABLE_TYPE } from '../mock_data';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('GeoReplicable', () => {
  let wrapper;

  const actionSpies = {
    setPage: jest.fn(),
    fetchReplicableItems: jest.fn(),
  };

  const createComponent = () => {
    wrapper = mount(GeoReplicable, {
      localVue,
      store: createStore({ replicableType: MOCK_REPLICABLE_TYPE, useGraphQl: false }),
      methods: {
        ...actionSpies,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  const findGeoReplicableContainer = () => wrapper.find('section');
  const findGlPagination = () => findGeoReplicableContainer().find(GlPagination);
  const findGeoReplicableItem = () => findGeoReplicableContainer().findAll(GeoReplicableItem);

  describe('template', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the replicable container', () => {
      expect(findGeoReplicableContainer().exists()).toBe(true);
    });

    describe('when useGraphQl is false', () => {
      describe('GlPagination', () => {
        describe('when perPage >= total', () => {
          beforeEach(() => {
            wrapper.vm.$store.state.paginationData.perPage = 2;
            wrapper.vm.$store.state.paginationData.total = 1;
          });

          it('is hidden', () => {
            expect(findGlPagination().isEmpty()).toBe(true);
          });
        });

        describe('when perPage < total', () => {
          beforeEach(() => {
            wrapper.vm.$store.state.paginationData.perPage = 1;
            wrapper.vm.$store.state.paginationData.total = 2;
          });

          it('renders', () => {
            expect(findGlPagination().html()).not.toBeUndefined();
          });
        });
      });
    });

    describe('when useGraphQl is true', () => {
      beforeEach(() => {
        createComponent();
        wrapper.vm.$store.state.useGraphQl = true;
      });

      it('does not render GlPagination', () => {
        expect(findGlPagination().exists()).toBeFalsy();
      });
    });

    describe('GeoReplicableItem', () => {
      beforeEach(() => {
        wrapper.vm.$store.state.replicableItems = MOCK_BASIC_FETCH_DATA_MAP;
      });

      it('renders an instance for each replicableItem in the store', () => {
        const replicableItemWrappers = findGeoReplicableItem();
        const replicableItems = [...wrapper.vm.$store.state.replicableItems];

        for (let i = 0; i < replicableItemWrappers.length; i += 1) {
          expect(replicableItemWrappers.at(i).props().projectId).toBe(replicableItems[i].projectId);
        }
      });
    });
  });

  describe('changing the page', () => {
    describe('when useGraphQl is false', () => {
      beforeEach(() => {
        createComponent();
        wrapper.vm.page = 2;
      });

      it('should call setPage', () => {
        expect(actionSpies.setPage).toHaveBeenCalledWith(2);
      });

      it('should call fetchReplicableItems', () => {
        expect(actionSpies.fetchReplicableItems).toHaveBeenCalled();
      });
    });
  });
});
