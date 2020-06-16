import { shallowMount } from '@vue/test-utils';
import GeoSettingsApp from 'ee/geo_settings/components/app.vue';
import GeoSettingsForm from 'ee/geo_settings/components/geo_settings_form.vue';

describe('GeoSettingsApp', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMount(GeoSettingsApp);
  };

  afterEach(() => {
    wrapper.destroy();
  });

  const findGeoSettingsContainer = () => wrapper.find('[data-testid="geoSettingsContainer"]');
  const findGeoSettingsForm = () => wrapper.find(GeoSettingsForm);

  describe('renders', () => {
    beforeEach(() => {
      createComponent();
    });

    it('the settings container', () => {
      expect(findGeoSettingsContainer().exists()).toBe(true);
    });

    it('header text', () => {
      expect(findGeoSettingsContainer().text()).toContain('Geo Settings');
    });

    it('Geo Settings Form', () => {
      expect(findGeoSettingsForm().exists()).toBe(true);
    });
  });
});
