import { shallowMount } from '@vue/test-utils';
import GeoNodeFormCore from 'ee/geo_node_form/components/geo_node_form_core.vue';
import { MOCK_NODE } from '../mock_data';

describe('GeoNodeFormCore', () => {
  let wrapper;

  const propsData = {
    nodeData: MOCK_NODE,
  };

  const createComponent = () => {
    wrapper = shallowMount(GeoNodeFormCore, {
      propsData,
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  const findGeoNodeFormNameField = () => wrapper.find('#node-name-field');
  const findGeoNodeFormUrlField = () => wrapper.find('#node-url-field');

  describe('template', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders Geo Node Form Name Field', () => {
      expect(findGeoNodeFormNameField().exists()).toBe(true);
    });

    it('renders Geo Node Form Url Field', () => {
      expect(findGeoNodeFormUrlField().exists()).toBe(true);
    });
  });
});
