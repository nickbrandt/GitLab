import Vuex from 'vuex';
import { createLocalVue, shallowMount } from '@vue/test-utils';
import { visitUrl } from '~/lib/utils/url_utility';
import store from 'ee/geo_settings/store';
import GeoSettingsForm from 'ee/geo_settings/components/geo_settings_form.vue';

const localVue = createLocalVue();
localVue.use(Vuex);

jest.mock('~/lib/utils/url_utility', () => ({
  visitUrl: jest.fn().mockName('visitUrlMock'),
}));

describe('GeoSettingsForm', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMount(GeoSettingsForm, {
      store,
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  const findGeoSettingsTimeoutField = () => wrapper.find('#settings-timeout-field');
  const findGeoSettingsAllowedIpField = () => wrapper.find('#settings-allowed-ip-field');
  const findSettingsCancelButton = () => wrapper.find('[data-testid="settingsCancelButton"]');

  describe('template', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders Geo Node Form Name Field', () => {
      expect(findGeoSettingsTimeoutField().exists()).toBe(true);
    });

    it('renders Geo Node Form Url Field', () => {
      expect(findGeoSettingsAllowedIpField().exists()).toBe(true);
    });
  });

  describe('methods', () => {
    describe('redirect', () => {
      beforeEach(() => {
        createComponent();
      });

      it('calls visitUrl when cancel is clicked', () => {
        findSettingsCancelButton().vm.$emit('click');
        expect(visitUrl).toHaveBeenCalledWith('/admin/geo/nodes');
      });
    });
  });
});
