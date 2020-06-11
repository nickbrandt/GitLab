import Vuex from 'vuex';
import { createLocalVue, mount } from '@vue/test-utils';
import { GlLink, GlButton } from '@gitlab/ui';
import GeoReplicableItem from 'ee/geo_replicable/components/geo_replicable_item.vue';
import createStore from 'ee/geo_replicable/store';
import { ACTION_TYPES } from 'ee/geo_replicable/constants';
import { MOCK_BASIC_FETCH_DATA_MAP, MOCK_REPLICABLE_TYPE } from '../mock_data';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('GeoReplicableItem', () => {
  let wrapper;
  const mockReplicable = MOCK_BASIC_FETCH_DATA_MAP[0];

  const actionSpies = {
    initiateReplicableSync: jest.fn(),
  };

  const propsData = {
    name: mockReplicable.name,
    projectId: mockReplicable.projectId,
    syncStatus: mockReplicable.state,
    lastSynced: mockReplicable.lastSyncedAt,
    lastVerified: null,
    lastChecked: null,
  };

  const createComponent = () => {
    wrapper = mount(GeoReplicableItem, {
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

      it('calls initiateReplicableSync when clicked', () => {
        findGlButton().trigger('click');
        expect(actionSpies.initiateReplicableSync).toHaveBeenCalledWith({
          projectId: propsData.projectId,
          name: propsData.name,
          action: ACTION_TYPES.RESYNC,
        });
      });
    });
  });
});
