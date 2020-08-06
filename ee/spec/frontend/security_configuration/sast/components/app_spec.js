import { shallowMount } from '@vue/test-utils';
import { GlAlert, GlLink, GlLoadingIcon, GlSprintf } from '@gitlab/ui';
import SASTConfigurationApp from 'ee/security_configuration/sast/components/app.vue';
import DynamicFields from 'ee/security_configuration/sast/components/dynamic_fields.vue';
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
  const findDynamicFields = () => wrapper.find(DynamicFields);
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

    it('does not display the dynamic fields component', () => {
      expect(findDynamicFields().exists()).toBe(false);
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

    it('does not display the dynamic fields component', () => {
      expect(findDynamicFields().exists()).toBe(false);
    });

    it('displays an alert message', () => {
      expect(findErrorAlert().exists()).toBe(true);
    });
  });

  describe('when loaded', () => {
    const entities = makeEntities(3);

    beforeEach(() => {
      createComponent({
        sastConfigurationEntities: entities,
      });
    });

    it('does not display a loading spinner', () => {
      expect(findLoadingIcon().exists()).toBe(false);
    });

    it('displays the dynamic fields component', () => {
      const dynamicFields = findDynamicFields();
      expect(dynamicFields.exists()).toBe(true);
      expect(dynamicFields.props('entities')).toBe(entities);
    });

    it('does not display an alert message', () => {
      expect(findErrorAlert().exists()).toBe(false);
    });

    describe('when the dynamic fields component emits an input event', () => {
      let dynamicFields;
      let newEntities;

      beforeEach(() => {
        dynamicFields = findDynamicFields();
        newEntities = makeEntities(3, { value: 'foo' });
        dynamicFields.vm.$emit(DynamicFields.model.event, newEntities);
      });

      it('updates the entities binding', () => {
        expect(dynamicFields.props('entities')).toBe(newEntities);
      });
    });
  });
});
