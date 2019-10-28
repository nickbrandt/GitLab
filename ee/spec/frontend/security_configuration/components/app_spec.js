import { shallowMount, createLocalVue } from '@vue/test-utils';

import { GlLink } from '@gitlab/ui';
import SecurityConfigurationApp from 'ee/security_configuration/components/app.vue';

const localVue = createLocalVue();

describe('Security Configuration App', () => {
  let wrapper;
  const createComponent = (props = {}) => {
    wrapper = shallowMount(SecurityConfigurationApp, {
      localVue,
      propsData: {
        helpPagePath: '',
        features: [],
        ...props,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  const getHelpLink = () => wrapper.find('header').find(GlLink);
  const getFeatureConfigRows = () => wrapper.findAll('.js-feature-config-row');
  const getFirstFeatureConfigRow = () => getFeatureConfigRows().at(0);
  const getFirstFeatureLink = () => getFirstFeatureConfigRow().find(GlLink);

  it('contains a link to the given help page', () => {
    const helpPagePath = 'foo';

    createComponent({ helpPagePath });

    expect(getHelpLink().attributes('href')).toBe(helpPagePath);
  });

  it('renders the full list of features', () => {
    const features = [{}, {}, {}];

    createComponent({ features });

    expect(getFeatureConfigRows().length).toBe(features.length);
  });

  it('renders a given features information', () => {
    const name = 'foo';
    const description = 'bar';
    const link = 'http://baz';
    const features = [{ name, description, link }];

    createComponent({ features });

    expect(getFirstFeatureConfigRow().text()).toContain(name);
    expect(getFirstFeatureConfigRow().text()).toContain(description);
    expect(getFirstFeatureLink().attributes('href')).toBe(link);
  });

  it.each`
    configured | statusText
    ${true}    | ${'Configured'}
    ${false}   | ${'Not yet'}
  `('renders a given features configuration status', ({ configured, statusText }) => {
    const features = [{ configured }];

    createComponent({ features });

    expect(wrapper.find('.js-feature-config-status').text()).toBe(statusText);
  });
});
