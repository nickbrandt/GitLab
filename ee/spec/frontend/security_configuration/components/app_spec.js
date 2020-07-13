import { mount } from '@vue/test-utils';
import { merge } from 'lodash';
import { GlAlert, GlLink } from '@gitlab/ui';
import SecurityConfigurationApp from 'ee/security_configuration/components/app.vue';
import stubChildren from 'helpers/stub_children';

const propsData = {
  features: [],
  autoDevopsEnabled: false,
  latestPipelinePath: 'http://latestPipelinePath',
  autoDevopsHelpPagePath: 'http://autoDevopsHelpPagePath',
  autoDevopsPath: 'http://autoDevopsPath',
  helpPagePath: 'http://helpPagePath',
  autoFixSettingsProps: {},
};

describe('Security Configuration App', () => {
  let wrapper;
  const createComponent = (options = {}) => {
    wrapper = mount(
      SecurityConfigurationApp,
      merge(
        {},
        {
          stubs: {
            ...stubChildren(SecurityConfigurationApp),
            GlTable: false,
            GlSprintf: false,
          },
          propsData,
        },
        options,
      ),
    );
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
  const getAlert = () => wrapper.find(GlAlert);

  describe('header', () => {
    it.each`
      autoDevopsEnabled | expectedUrl
      ${true}           | ${propsData.autoDevopsHelpPagePath}
      ${false}          | ${propsData.latestPipelinePath}
    `(
      'displays a link to "$expectedUrl" when autoDevops is "$autoDevopsEnabled"',
      ({ autoDevopsEnabled, expectedUrl }) => {
        createComponent({ propsData: { autoDevopsEnabled } });

        expect(getPipelinesLink().attributes('href')).toBe(expectedUrl);
        expect(getPipelinesLink().attributes('target')).toBe('_blank');
      },
    );
  });

  describe('Auto DevOps alert', () => {
    describe.each`
      gitlabCiPresent | autoDevopsEnabled | canEnableAutoDevops | sastConfigurationByClick | shouldShowAlert
      ${false}        | ${false}          | ${true}             | ${true}                  | ${true}
      ${true}         | ${false}          | ${true}             | ${true}                  | ${false}
      ${false}        | ${true}           | ${true}             | ${true}                  | ${false}
      ${false}        | ${false}          | ${false}            | ${true}                  | ${false}
      ${false}        | ${false}          | ${true}             | ${false}                 | ${false}
    `(
      'given gitlabCiPresent is $gitlabCiPresent, autoDevopsEnabled is $autoDevopsEnabled, canEnableAutoDevops is $canEnableAutoDevops, sastConfigurationByClick is $sastConfigurationByClick',
      ({
        gitlabCiPresent,
        autoDevopsEnabled,
        canEnableAutoDevops,
        sastConfigurationByClick,
        shouldShowAlert,
      }) => {
        beforeEach(() => {
          createComponent({
            propsData: {
              gitlabCiPresent,
              autoDevopsEnabled,
              canEnableAutoDevops,
            },
            provide: { glFeatures: { sastConfigurationByClick } },
          });
        });

        it(`is${shouldShowAlert ? '' : ' not'} rendered`, () => {
          expect(getAlert().exists()).toBe(shouldShowAlert);
        });

        if (shouldShowAlert) {
          it('has the expected text', () => {
            expect(getAlert().text()).toMatchInterpolatedText(
              SecurityConfigurationApp.autoDevopsAlertMessage,
            );
          });

          it('has a link to the Auto DevOps docs', () => {
            const link = getAlert().find(GlLink);
            expect(link.attributes().href).toBe(propsData.autoDevopsHelpPagePath);
          });

          it('has the correct primary button', () => {
            expect(getAlert().props()).toMatchObject({
              title: 'Auto DevOps',
              primaryButtonText: 'Enable Auto DevOps',
              primaryButtonLink: propsData.autoDevopsPath,
              dismissible: false,
            });
          });
        }
      },
    );
  });

  describe('features table', () => {
    it('passes the expected data to the GlTable', () => {
      const features = generateFeatures(5);

      createComponent({ propsData: { features } });

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
