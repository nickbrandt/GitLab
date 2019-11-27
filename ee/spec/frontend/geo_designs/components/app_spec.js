import Vuex from 'vuex';
import { createLocalVue, shallowMount } from '@vue/test-utils';
import GeoDesignsApp from 'ee/geo_designs/components/app.vue';
import store from 'ee/geo_designs/store';
import GeoDesignsDisabled from 'ee/geo_designs/components/geo_designs_disabled.vue';
import {
  MOCK_GEO_SVG_PATH,
  MOCK_GEO_TROUBLESHOOTING_LINK,
  MOCK_DESIGN_MANAGEMENT_LINK,
} from '../mock_data';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('GeoDesignsApp', () => {
  let wrapper;

  const propsData = {
    geoSvgPath: MOCK_GEO_SVG_PATH,
    geoTroubleshootingLink: MOCK_GEO_TROUBLESHOOTING_LINK,
    designManagementLink: MOCK_DESIGN_MANAGEMENT_LINK,
    designsEnabled: true,
  };

  const createComponent = () => {
    wrapper = shallowMount(localVue.extend(GeoDesignsApp), {
      localVue,
      store,
      propsData,
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  const findGeoDesignsContainer = () => wrapper.find('.geo-designs-container');
  const findDesignsComingSoon = () => findGeoDesignsContainer().find('h2');
  const findGeoDesignsDisabled = () => findGeoDesignsContainer().find(GeoDesignsDisabled);

  describe('template', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the design container', () => {
      expect(findGeoDesignsContainer().exists()).toBe(true);
    });

    describe('when designsEnabled = false', () => {
      beforeEach(() => {
        propsData.designsEnabled = false;
        createComponent();
      });

      it('hides designs coming soon text', () => {
        expect(findDesignsComingSoon().exists()).toBe(false);
      });

      it('shows designs disabled component', () => {
        expect(findGeoDesignsDisabled().exists()).toBe(true);
      });
    });

    describe('when designsEnabled = true', () => {
      beforeEach(() => {
        propsData.designsEnabled = true;
        createComponent();
      });

      it('shows designs coming soon text', () => {
        expect(findDesignsComingSoon().exists()).toBe(true);
      });

      it('hides designs disabled component', () => {
        expect(findGeoDesignsDisabled().exists()).toBe(false);
      });
    });
  });
});
