import { shallowMount } from '@vue/test-utils';
import GeoNodeFormApp from 'ee/geo_node_form/components/app.vue';

describe('GeoNodeFormApp', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMount(GeoNodeFormApp);
  };

  afterEach(() => {
    wrapper.destroy();
  });

  const findGeoNodeFormContainer = () => wrapper.find('.geo-node-form-container');

  describe('render', () => {
    beforeEach(() => {
      createComponent();
    });

    it('the node form container', () => {
      expect(findGeoNodeFormContainer().exists()).toBe(true);
    });

    it('`Geo Node Form` header text', () => {
      expect(findGeoNodeFormContainer().text()).toContain('Geo Node Form');
    });
  });
});
