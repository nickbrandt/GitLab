import { shallowMount } from '@vue/test-utils';
import { visitUrl } from '~/lib/utils/url_utility';
import GeoNodeForm from 'ee/geo_node_form/components/geo_node_form.vue';
import GeoNodeFormCore from 'ee/geo_node_form/components/geo_node_form_core.vue';
import GeoNodeFormCapacities from 'ee/geo_node_form/components/geo_node_form_capacities.vue';
import { MOCK_NODE, MOCK_SELECTIVE_SYNC_TYPES, MOCK_SYNC_SHARDS } from '../mock_data';

jest.mock('~/lib/utils/url_utility', () => ({
  visitUrl: jest.fn().mockName('visitUrlMock'),
}));

describe('GeoNodeForm', () => {
  let wrapper;

  const propsData = {
    node: MOCK_NODE,
    selectiveSyncTypes: MOCK_SELECTIVE_SYNC_TYPES,
    syncShardsOptions: MOCK_SYNC_SHARDS,
  };

  const createComponent = () => {
    wrapper = shallowMount(GeoNodeForm, {
      propsData,
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  const findGeoNodeFormCoreField = () => wrapper.find(GeoNodeFormCore);
  const findGeoNodePrimaryField = () => wrapper.find('#node-primary-field');
  const findGeoNodeInternalUrlField = () => wrapper.find('#node-internal-url-field');
  const findGeoNodeFormCapacitiesField = () => wrapper.find(GeoNodeFormCapacities);
  const findGeoNodeObjectStorageField = () => wrapper.find('#node-object-storage-field');
  const findGeoNodeCancelButton = () => wrapper.find('#node-cancel-button');

  describe('template', () => {
    beforeEach(() => {
      createComponent();
    });

    describe.each`
      primaryNode | showCore | showPrimary | showInternalUrl | showCapacities | showObjectStorage
      ${true}     | ${true}  | ${true}     | ${true}         | ${true}        | ${false}
      ${false}    | ${true}  | ${true}     | ${false}        | ${true}        | ${true}
    `(
      `conditional fields`,
      ({
        primaryNode,
        showCore,
        showPrimary,
        showInternalUrl,
        showCapacities,
        showObjectStorage,
      }) => {
        beforeEach(() => {
          wrapper.setData({
            nodeData: { ...wrapper.vm.nodeData, primary: primaryNode },
          });
        });

        it(`it ${showCore ? 'shows' : 'hides'} the Core Field`, () => {
          expect(findGeoNodeFormCoreField().exists()).toBe(showCore);
        });

        it(`it ${showPrimary ? 'shows' : 'hides'} the Primary Field`, () => {
          expect(findGeoNodePrimaryField().exists()).toBe(showPrimary);
        });

        it(`it ${showInternalUrl ? 'shows' : 'hides'} the Internal URL Field`, () => {
          expect(findGeoNodeInternalUrlField().exists()).toBe(showInternalUrl);
        });

        it(`it ${showCapacities ? 'shows' : 'hides'} the Capacities Field`, () => {
          expect(findGeoNodeFormCapacitiesField().exists()).toBe(showCapacities);
        });

        it(`it ${showObjectStorage ? 'shows' : 'hides'} the Object Storage Field`, () => {
          expect(findGeoNodeObjectStorageField().exists()).toBe(showObjectStorage);
        });
      },
    );
  });

  describe('methods', () => {
    describe('redirect', () => {
      beforeEach(() => {
        createComponent();
      });

      it('calls visitUrl when cancel is clicked', () => {
        findGeoNodeCancelButton().vm.$emit('click');
        expect(visitUrl).toHaveBeenCalled();
      });
    });

    describe('addSyncOption', () => {
      beforeEach(() => {
        createComponent();
      });

      it('should add value to nodeData', () => {
        expect(wrapper.vm.nodeData.selectiveSyncShards).toEqual([]);
        wrapper.vm.addSyncOption({ key: 'selectiveSyncShards', value: MOCK_SYNC_SHARDS[0].value });
        expect(wrapper.vm.nodeData.selectiveSyncShards).toEqual([MOCK_SYNC_SHARDS[0].value]);
      });
    });

    describe('removeSyncOption', () => {
      beforeEach(() => {
        createComponent();
        wrapper.setData({
          nodeData: { ...wrapper.vm.nodeData, selectiveSyncShards: [MOCK_SYNC_SHARDS[0].value] },
        });
      });

      it('should remove value from nodeData', () => {
        expect(wrapper.vm.nodeData.selectiveSyncShards).toEqual([MOCK_SYNC_SHARDS[0].value]);
        wrapper.vm.removeSyncOption({ key: 'selectiveSyncShards', index: 0 });
        expect(wrapper.vm.nodeData.selectiveSyncShards).toEqual([]);
      });
    });
  });

  describe('created', () => {
    describe('when node prop exists', () => {
      beforeEach(() => {
        createComponent();
      });

      it('sets nodeData to the correct node', () => {
        expect(wrapper.vm.nodeData.id).toBe(wrapper.vm.node.id);
      });
    });

    describe('when node prop does not exist', () => {
      beforeEach(() => {
        propsData.node = null;
        createComponent();
      });

      it('sets nodeData to the default node data', () => {
        expect(wrapper.vm.nodeData).not.toBeNull();
        expect(wrapper.vm.nodeData.id).not.toBe(MOCK_NODE.id);
      });
    });
  });
});
