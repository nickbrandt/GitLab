import { merge } from 'lodash';
import { shallowMount } from '@vue/test-utils';
import ManageFeature from 'ee/security_configuration/components/manage_feature.vue';
import CreateMergeRequestButton from 'ee/security_configuration/components/create_merge_request_button.vue';
import { generateFeatures } from './helpers';

const createSastMergeRequestPath = '/create_sast_merge_request_path';

describe('ManageFeature component', () => {
  let wrapper;
  let feature;

  const createComponent = options => {
    wrapper = shallowMount(
      ManageFeature,
      merge(
        {
          propsData: {
            createSastMergeRequestPath,
            gitlabCiPresent: false,
            autoDevopsEnabled: false,
          },
        },
        options,
      ),
    );
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  const findCreateMergeRequestButton = () => wrapper.find(CreateMergeRequestButton);
  const findTestId = id => wrapper.find(`[data-testid="${id}"]`);

  describe('given sastConfigurationUi feature flag is enabled', () => {
    const featureFlagEnabled = {
      provide: {
        glFeatures: {
          sastConfigurationUi: true,
        },
      },
    };

    describe.each`
      autoDevopsEnabled | expectedTestId
      ${true}           | ${'configureButton'}
      ${false}          | ${'enableButton'}
    `('given autoDevopsEnabled is $autoDevopsEnabled', ({ autoDevopsEnabled, expectedTestId }) => {
      describe('given no CI file and feature with a configuration path', () => {
        beforeEach(() => {
          [feature] = generateFeatures(1, { configuration_path: 'foo' });

          createComponent({
            ...featureFlagEnabled,
            propsData: { feature, gitlabCiPresent: false, autoDevopsEnabled },
          });
        });

        it('shows a button to configure the feature', () => {
          const button = findTestId(expectedTestId);
          expect(button.exists()).toBe(true);
          expect(button.attributes('href')).toBe(feature.configuration_path);
        });
      });
    });
  });

  describe('given a feature with type "sast" and no CI file', () => {
    const autoDevopsEnabled = true;

    beforeEach(() => {
      [feature] = generateFeatures(1, { type: 'sast' });

      createComponent({
        propsData: { feature, gitlabCiPresent: false, autoDevopsEnabled },
      });
    });

    it('shows the CreateMergeRequestButton component', () => {
      const button = findCreateMergeRequestButton();
      expect(button.exists()).toBe(true);
      expect(button.props()).toMatchObject({
        endpoint: createSastMergeRequestPath,
        autoDevopsEnabled,
      });
    });
  });

  describe.each`
    featureProps        | gitlabCiPresent
    ${{ type: 'sast' }} | ${true}
    ${{}}               | ${false}
  `(
    'given a featureProps with $featureProps and gitlabCiPresent is $gitlabCiPresent',
    ({ featureProps, gitlabCiPresent }) => {
      beforeEach(() => {
        [feature] = generateFeatures(1, featureProps);

        createComponent({
          propsData: { feature, gitlabCiPresent },
        });
      });

      it('shows docs link for feature', () => {
        const link = findTestId('docsLink');
        expect(link.exists()).toBe(true);
        expect(link.attributes('aria-label')).toContain(feature.name);
        expect(link.attributes('href')).toBe(feature.link);
      });
    },
  );
});
