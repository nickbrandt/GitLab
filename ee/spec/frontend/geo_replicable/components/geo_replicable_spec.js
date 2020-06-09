import Vuex from 'vuex';
import { createLocalVue, mount } from '@vue/test-utils';
import { GlPagination } from '@gitlab/ui';
import store from 'ee/geo_replicable/store';
import GeoReplicable from 'ee/geo_replicable/components/geo_replicable.vue';
import GeoReplicableItem from 'ee/geo_replicable/components/geo_replicable_item.vue';
import { MOCK_BASIC_FETCH_DATA_MAP } from '../mock_data';

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
      store,
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

    describe('GlPagination', () => {
      describe('when pageSize >= totalReplicableItems', () => {
        beforeEach(() => {
          wrapper.vm.$store.state.pageSize = 2;
          wrapper.vm.$store.state.totalReplicableItems = 1;
        });

        it('is hidden', () => {
          expect(findGlPagination().isEmpty()).toBe(true);
        });
      });

      describe('when pageSize < totalReplicableItems', () => {
        beforeEach(() => {
          wrapper.vm.$store.state.pageSize = 1;
          wrapper.vm.$store.state.totalReplicableItems = 2;
        });

        it('renders', () => {
          expect(findGlPagination().html()).not.toBeUndefined();
        });
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
