import { shallowMount } from '@vue/test-utils';
import GeoNodeFormApp from 'ee/geo_node_form/components/app.vue';
import GeoNodeForm from 'ee/geo_node_form/components/geo_node_form.vue';
import { MOCK_SELECTIVE_SYNC_TYPES, MOCK_SYNC_SHARDS, MOCK_NODE } from '../mock_data';

describe('GeoNodeFormApp', () => {
  let wrapper;

  const propsData = {
    selectiveSyncTypes: MOCK_SELECTIVE_SYNC_TYPES,
    syncShardsOptions: MOCK_SYNC_SHARDS,
    node: undefined,
  };

  const createComponent = () => {
    wrapper = shallowMount(GeoNodeFormApp, {
      propsData,
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  const findGeoNodeFormTitle = () => wrapper.find('.page-title');
  const findGeoForm = () => wrapper.find(GeoNodeForm);

  describe('render', () => {
    beforeEach(() => {
      createComponent();
    });

    it('the Geo Node Form Title', () => {
      expect(findGeoNodeFormTitle().exists()).toBe(true);
    });

    it('the Geo Node Form', () => {
      expect(findGeoForm().exists()).toBe(true);
    });
  });

  describe('Geo Node Form Title', () => {
    describe('when props.node is undefined', () => {
      beforeEach(() => {
        createComponent();
      });

      it('sets title to `New Geo Node`', () => {
        expect(findGeoNodeFormTitle().text()).toBe('New Geo Node');
      });
    });

    describe('when props.node is set', () => {
      beforeEach(() => {
        propsData.node = MOCK_NODE;
        createComponent();
      });

      it('sets title to `Edit Geo Node`', () => {
        expect(findGeoNodeFormTitle().text()).toBe('Edit Geo Node');
      });
    });
  });
});
