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
        features: [],
        autoDevOpsEnabled: false,
        latestPipelinePath: '',
        autoDevOpsHelpPagePath: '',
        helpPagePath: '',
        ...props,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  const getHelpLink = () => wrapper.find('header').find(GlLink);
  const getAllFeatureConfigRows = () => wrapper.findAll('.js-feature-config-row');
  const getFirstFeatureConfigRow = () => getAllFeatureConfigRows().at(0);
  const getFeatureLink = () => getFirstFeatureConfigRow().find(GlLink);
  const getFeatureConfigStatus = () => wrapper.find('.js-feature-config-status');
  const getNotification = () => wrapper.find('.js-security-configuration-notification');
  const getPipelinesLink = () => getNotification().find('a');

  it('displays a link to the given help page', () => {
    const helpPagePath = 'http://foo';

    createComponent({ helpPagePath });

    expect(getHelpLink().attributes('href')).toBe(helpPagePath);
  });

  it.each`
    autoDevOpsEnabled | latestPipelinePath         | autoDevOpsHelpPagePath         | expectedUrl
    ${true}           | ${'http://latestPipeline'} | ${'http://autoDevOpsHelpPath'} | ${'http://autoDevOpsHelpPath'}
    ${false}          | ${'http://latestPipeline'} | ${'http://autoDevOpsHelpPath'} | ${'http://latestPipeline'}
  `(
    'displays a secure link with the href "$expectedUrl" if autoDevOpsEnabled is "$autoDevOpsEnabled',
    ({ autoDevOpsEnabled, latestPipelinePath, autoDevOpsHelpPagePath, expectedUrl }) => {
      createComponent({ autoDevOpsEnabled, latestPipelinePath, autoDevOpsHelpPagePath });

      expect(getPipelinesLink().attributes('href')).toBe(expectedUrl);
      expect(getPipelinesLink().attributes('rel')).toBe('noopener');
    },
  );

  it('displays a full list of given features', () => {
    const features = [{}, {}, {}];

    createComponent({ features });

    expect(getAllFeatureConfigRows().length).toBe(features.length);
  });

  it('displays information about a given feature', () => {
    const name = 'foo';
    const description = 'bar';
    const link = 'http://baz';
    const features = [{ name, description, link }];

    createComponent({ features });

    expect(getFirstFeatureConfigRow().text()).toContain(name);
    expect(getFirstFeatureConfigRow().text()).toContain(description);
    expect(getFeatureLink().attributes('href')).toBe(link);
  });

  it.each`
    configured | statusText
    ${true}    | ${'Configured'}
    ${false}   | ${'Not yet'}
  `(
    `displays "$statusText" if the given feature's configuration status is: "$configured"`,
    ({ configured, statusText }) => {
      const features = [{ configured }];

      createComponent({ features });

      expect(getFeatureConfigStatus().text()).toBe(statusText);
    },
  );
});
