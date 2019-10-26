import { shallowMount, createLocalVue } from '@vue/test-utils';

import SecurityConfigurationApp from 'ee/security_configuration/components/app.vue';

const localVue = createLocalVue();

describe('Security Configuration App', () => {
  let wrapper;
  const createComponent = (props = {}) => {
    wrapper = shallowMount(SecurityConfigurationApp, {
      localVue,
      propsData: {
        helpPagePath: '',
        ...props,
      },
    });
  };

  beforeEach(createComponent);

  it('has a heading', () => {
    expect(wrapper.find('h2').exists()).toBe(true);
  });
});
