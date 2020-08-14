import { shallowMount } from '@vue/test-utils';
import { GlAlert, GlLink, GlLoadingIcon, GlSprintf } from '@gitlab/ui';
import SASTConfigurationApp from 'ee/security_configuration/sast/components/app.vue';
import ConfigurationForm from 'ee/security_configuration/sast/components/configuration_form.vue';
import { makeEntities } from './helpers';

const sastDocumentationPath = '/help/sast';
const projectPath = 'namespace/project';

describe('SAST Configuration App', () => {
  let wrapper;

  const createComponent = ({
    provide = {},
    stubs = {},
    loading = false,
    hasLoadingError = false,
    sastConfigurationEntities = [],
  } = {}) => {
    wrapper = shallowMount(SASTConfigurationApp, {
      mocks: { $apollo: { loading } },
      stubs,
      provide: {
        sastDocumentationPath,
        projectPath,
        ...provide,
      },
    });

    // While setData is usually frowned upon, it is the documented way of
    // mocking GraphQL response data:
    // https://docs.gitlab.com/ee/development/fe_guide/graphql.html#testing
    wrapper.setData({
      hasLoadingError,
      sastConfigurationEntities,
    });
  };

  const findHeader = () => wrapper.find('header');
  const findSubHeading = () => findHeader().find('p');
  const findLink = (container = wrapper) => container.find(GlLink);
  const findConfigurationForm = () => wrapper.find(ConfigurationForm);
  const findLoadingIcon = () => wrapper.find(GlLoadingIcon);
  const findErrorAlert = () => wrapper.find(GlAlert);

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('header', () => {
    beforeEach(() => {
      createComponent({
        stubs: { GlSprintf },
      });
    });

    it('displays a link to sastDocumentationPath', () => {
      expect(findLink(findHeader()).attributes('href')).toBe(sastDocumentationPath);
    });

    it('displays the subheading', () => {
      expect(findSubHeading().text()).toMatchInterpolatedText(SASTConfigurationApp.i18n.helpText);
    });
  });

  describe('when loading', () => {
    beforeEach(() => {
      createComponent({
        loading: true,
      });
    });

    it('displays a loading spinner', () => {
      expect(findLoadingIcon().exists()).toBe(true);
    });

    it('does not display the configuration form', () => {
      expect(findConfigurationForm().exists()).toBe(false);
    });

    it('does not display an alert message', () => {
      expect(findErrorAlert().exists()).toBe(false);
    });
  });

  describe('when loading failed', () => {
    beforeEach(() => {
      createComponent({
        hasLoadingError: true,
      });
    });

    it('does not display a loading spinner', () => {
      expect(findLoadingIcon().exists()).toBe(false);
    });

    it('does not display the configuration form', () => {
      expect(findConfigurationForm().exists()).toBe(false);
    });

    it('displays an alert message', () => {
      expect(findErrorAlert().exists()).toBe(true);
    });
  });

  describe('when loaded', () => {
    let entities;

    beforeEach(() => {
      entities = makeEntities(3);
      createComponent({
        sastConfigurationEntities: entities,
      });
    });

    it('does not display a loading spinner', () => {
      expect(findLoadingIcon().exists()).toBe(false);
    });

    it('displays the configuration form', () => {
      expect(findConfigurationForm().exists()).toBe(true);
    });

    it('passes the sastConfigurationEntities to the entities prop', () => {
      expect(findConfigurationForm().props('entities')).toBe(entities);
    });

    it('does not display an alert message', () => {
      expect(findErrorAlert().exists()).toBe(false);
    });
  });
});
