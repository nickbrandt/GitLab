import { GlTable } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';

import IntegrationOverrides from '~/integrations/overrides/components/integration_overrides.vue';

import axios from '~/lib/utils/axios_utils';

describe('IntegrationOverrides', () => {
  let wrapper;
  let mockAxios;

  const defaultProps = {
    endpoint: 'mock/endpoint',
  };

  const createComponent = () => {
    wrapper = shallowMount(IntegrationOverrides, {
      propsData: defaultProps,
    });
  };

  beforeEach(() => {
    mockAxios = new MockAdapter(axios);
    mockAxios.onGet(defaultProps.endpoint).replyOnce(200, []);
  });

  afterEach(() => {
    mockAxios.restore();
    wrapper.destroy();
  });

  const findGlTable = () => wrapper.findComponent(GlTable);

  describe('template', () => {
    it('renders GlTable', () => {
      createComponent();

      expect(findGlTable().exists()).toBe(true);
    });
  });
});
