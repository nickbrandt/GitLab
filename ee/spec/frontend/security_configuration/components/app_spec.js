import { mount } from '@vue/test-utils';
import { GlLink } from '@gitlab/ui';
import SecurityConfigurationApp from 'ee/security_configuration/components/app.vue';
import stubChildren from 'helpers/stub_children';

describe('Security Configuration App', () => {
  let wrapper;
  const createComponent = (props = {}) => {
    wrapper = mount(SecurityConfigurationApp, {
      stubs: {
        ...stubChildren(SecurityConfigurationApp),
        GlTable: false,
        GlSprintf: false,
      },
      propsData: {
        features: [],
        autoDevopsEnabled: false,
        latestPipelinePath: 'http://latestPipelinePath',
        autoDevopsHelpPagePath: 'http://autoDevopsHelpPagePath',
        helpPagePath: 'http://helpPagePath',
        autoFixSettingsProps: {},
        ...props,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  const generateFeatures = n => {
    return [...Array(n).keys()].map(i => ({
      name: `name-feature-${i}`,
      description: `description-feature-${i}`,
      link: `link-feature-${i}`,
      configured: i % 2 === 0,
    }));
  };

  const getPipelinesLink = () => wrapper.find({ ref: 'pipelinesLink' });
  const getFeaturesTable = () => wrapper.find({ ref: 'securityControlTable' });

  describe('header', () => {
    it.each`
      autoDevopsEnabled | expectedUrl
      ${true}           | ${'http://autoDevopsHelpPagePath'}
      ${false}          | ${'http://latestPipelinePath'}
    `(
      'displays a link to "$expectedUrl" when autoDevops is "$autoDevopsEnabled"',
      ({ autoDevopsEnabled, expectedUrl }) => {
        createComponent({ autoDevopsEnabled });

        expect(getPipelinesLink().attributes('href')).toBe(expectedUrl);
        expect(getPipelinesLink().attributes('target')).toBe('_blank');
      },
    );
  });

  describe('features table', () => {
    it('passes the expected data to the GlTable', () => {
      const features = generateFeatures(5);

      createComponent({ features });

      expect(getFeaturesTable().classes('b-table-stacked-md')).toBeTruthy();
      const rows = getFeaturesTable().findAll('tbody tr');
      expect(rows).toHaveLength(5);

      for (let i = 0; i < features.length; i += 1) {
        const [feature, status] = rows.at(i).findAll('td').wrappers;
        expect(feature.text()).toMatch(features[i].name);
        expect(feature.text()).toMatch(features[i].description);
        expect(feature.find(GlLink).attributes('href')).toBe(features[i].link);
        expect(status.text()).toMatch(features[i].configured ? 'Enabled' : 'Not yet enabled');
      }
    });
  });
});
