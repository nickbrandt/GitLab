import Vuex from 'vuex';
import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import { GlBreadcrumb, GlLoadingIcon } from '@gitlab/ui';
import httpStatusCodes from '~/lib/utils/http_status';
import ReportsApp from 'ee/analytics/reports/components/app.vue';
import createStore from 'ee/analytics/reports/store';
import { initialState, configData, pageData } from 'ee_jest/analytics/reports/mock_data';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('ReportsApp', () => {
  let wrapper;
  let mock;

  const createComponent = () => {
    const component = shallowMount(ReportsApp, {
      localVue,
      store: createStore(),
    });

    component.vm.$store.dispatch('page/setInitialPageData', pageData);

    return component;
  };

  const findGlBreadcrumb = () => wrapper.find(GlBreadcrumb);
  const findGlLoadingIcon = () => wrapper.find(GlLoadingIcon);

  beforeEach(() => {
    mock = new MockAdapter(axios);
    mock.onGet().reply(httpStatusCodes.OK, configData);
  });

  afterEach(() => {
    mock.restore();

    wrapper.destroy();
    wrapper = null;
  });

  describe('loading icon', () => {
    it('displays the icon while page config is being retrieved', async () => {
      wrapper = createComponent();

      await wrapper.vm.$nextTick();

      expect(findGlLoadingIcon().exists()).toBe(true);
    });

    it('hides the icon once page config has being retrieved', async () => {
      wrapper = createComponent();

      wrapper.vm.$store.dispatch('page/receivePageConfigDataSuccess', configData);

      await wrapper.vm.$nextTick();

      expect(findGlLoadingIcon().exists()).toBe(false);
    });
  });

  describe('contains the correct breadcrumbs', () => {
    it('displays the "Report" title by default', () => {
      wrapper = createComponent();

      const {
        config: { title },
      } = initialState;

      expect(findGlBreadcrumb().props('items')).toStrictEqual([{ text: title, href: '' }]);
    });

    describe('with a config specified', () => {
      it('displays the group name and report title once retrieved', async () => {
        wrapper = createComponent();

        wrapper.vm.$store.dispatch('page/receivePageConfigDataSuccess', configData);

        await wrapper.vm.$nextTick();

        const { groupName, groupPath } = pageData;
        const { title } = configData;

        expect(findGlBreadcrumb().props('items')).toStrictEqual([
          { text: groupName, href: `/${groupPath}` },
          { text: title, href: '' },
        ]);
      });
    });
  });
});
