import Vuex from 'vuex';
import { createLocalVue, mount } from '@vue/test-utils';
import { GlLink, GlButton } from '@gitlab/ui';
import GeoDesign from 'ee/geo_designs/components/geo_design.vue';
import store from 'ee/geo_designs/store';
import { ACTION_TYPES } from 'ee/geo_designs/store/constants';
import { MOCK_BASIC_FETCH_DATA_MAP } from '../mock_data';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('GeoDesignsApp', () => {
  let wrapper;
  const mockDesign = MOCK_BASIC_FETCH_DATA_MAP.data[0];

  const actionSpies = {
    initiateDesignSync: jest.fn(),
  };

  const propsData = {
    name: mockDesign.name,
    projectId: mockDesign.projectId,
    syncStatus: mockDesign.state,
    lastSynced: mockDesign.lastSyncedAt,
    lastVerified: null,
    lastChecked: null,
  };

  const createComponent = () => {
    wrapper = mount(GeoDesign, {
      localVue,
      store,
      propsData,
      methods: {
        ...actionSpies,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  const findCard = () => wrapper.find('.card');
  const findGlLink = () => findCard().find(GlLink);
  const findGlButton = () => findCard().find(GlButton);
  const findCardHeader = () => findCard().find('.card-header');
  const findCardBody = () => findCard().find('.card-body');

  describe('template', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders card', () => {
      expect(findCard().exists()).toBe(true);
    });

    it('renders card header', () => {
      expect(findCardHeader().exists()).toBe(true);
    });

    it('renders card body', () => {
      expect(findCardBody().exists()).toBe(true);
    });

    it('GlLink renders', () => {
      expect(findGlLink().exists()).toBe(true);
    });

    describe('ReSync Button', () => {
      it('renders', () => {
        expect(findGlButton().exists()).toBe(true);
      });

      it('calls initiateDesignSyncs when clicked', () => {
        findGlButton().trigger('click');
        expect(actionSpies.initiateDesignSync).toHaveBeenCalledWith({
          projectId: propsData.projectId,
          name: propsData.name,
          action: ACTION_TYPES.RESYNC,
        });
      });
    });
  });
});
