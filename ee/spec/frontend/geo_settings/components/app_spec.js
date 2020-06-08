import { shallowMount } from '@vue/test-utils';
import GeoSettingsApp from 'ee/geo_settings/components/app.vue';

describe('GeoSettingsApp', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMount(GeoSettingsApp);
  };

  afterEach(() => {
    wrapper.destroy();
  });

  const findGeoSettingsContainer = () => wrapper.find('[data-testid="geoSettingsContainer"]');

  describe('template', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the settings container', () => {
      expect(findGeoSettingsContainer().exists()).toBe(true);
    });

    it('`Geo Settings` header text', () => {
      expect(findGeoSettingsContainer().text()).toContain('Geo Settings');
    });
  });
});
