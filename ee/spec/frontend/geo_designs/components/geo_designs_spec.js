import Vuex from 'vuex';
import { createLocalVue, mount } from '@vue/test-utils';
import { GlPagination } from '@gitlab/ui';
import store from 'ee/geo_designs/store';
import GeoDesigns from 'ee/geo_designs/components/geo_designs.vue';
import GeoDesign from 'ee/geo_designs/components/geo_design.vue';
import { MOCK_BASIC_FETCH_DATA_MAP } from '../mock_data';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('GeoDesigns', () => {
  let wrapper;

  const actionSpies = {
    setPage: jest.fn(),
    fetchReplicableItems: jest.fn(),
  };

  const createComponent = () => {
    wrapper = mount(GeoDesigns, {
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

  const findGeoDesignsContainer = () => wrapper.find('section');
  const findGlPagination = () => findGeoDesignsContainer().find(GlPagination);
  const findGeoDesign = () => findGeoDesignsContainer().findAll(GeoDesign);

  describe('template', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the designs container', () => {
      expect(findGeoDesignsContainer().exists()).toBe(true);
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

    describe('GeoDesign', () => {
      beforeEach(() => {
        wrapper.vm.$store.state.replicableItems = MOCK_BASIC_FETCH_DATA_MAP.data;
      });

      it('renders an instance for each design in the store', () => {
        const designWrappers = findGeoDesign();
        const replicableItems = [...wrapper.vm.$store.state.replicableItems];

        for (let i = 0; i < designWrappers.length; i += 1) {
          expect(designWrappers.at(i).props().projectId).toBe(replicableItems[i].projectId);
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
