import { GlAlert, GlLoadingIcon, GlForm, GlFormInput } from '@gitlab/ui';
import VueApollo from 'vue-apollo';
import { createLocalVue, mount, shallowMount } from '@vue/test-utils';

import waitForPromises from 'helpers/wait_for_promises';
import createMockApollo from 'jest/helpers/mock_apollo_helper';

import getComplianceFrameworkQuery from 'ee/groups/settings/compliance_frameworks/graphql/queries/get_compliance_framework.query.graphql';
import createComplianceFrameworkMutation from 'ee/groups/settings/compliance_frameworks/graphql/queries/create_compliance_framework.mutation.graphql';
import updateComplianceFrameworkMutation from 'ee/groups/settings/compliance_frameworks/graphql/queries/update_compliance_framework.mutation.graphql';
import Form from 'ee/groups/settings/compliance_frameworks/components/form.vue';
import { visitUrl } from '~/lib/utils/url_utility';
import ColorPicker from '~/vue_shared/components/color_picker/color_picker.vue';

import {
  validGetResponse,
  validGetOneResponse,
  emptyGetResponse,
  validCreateResponse,
  errorCreateResponse,
  validUpdateResponse,
  errorUpdateResponse,
} from '../mock_data';

import * as Sentry from '~/sentry/wrapper';

const localVue = createLocalVue();
localVue.use(VueApollo);

jest.mock('~/lib/utils/url_utility', () => ({
  visitUrl: jest.fn().mockName('visitUrlMock'),
}));

describe('List', () => {
  let wrapper;
  const sentryError = new Error('Network error');
  const sentrySaveError = new Error('Invalid values given');
  const defaultPropsData = {
    groupPath: 'group-1',
    groupEditPath: 'group-1/edit',
    scopedLabelsHelpPath: 'help/scoped-labels',
  };

  const fetch = jest.fn().mockResolvedValue(validGetResponse);
  const fetchOne = jest.fn().mockResolvedValue(validGetOneResponse);
  const fetchEmpty = jest.fn().mockResolvedValue(emptyGetResponse);
  const fetchLoading = jest.fn().mockResolvedValue(new Promise(() => {}));
  const fetchWithErrors = jest.fn().mockRejectedValue(sentryError);

  const create = jest.fn().mockResolvedValue(validCreateResponse);
  const createWithNetworkErrors = jest.fn().mockRejectedValue(sentryError);
  const createWithErrors = jest.fn().mockResolvedValue(errorCreateResponse);

  const update = jest.fn().mockResolvedValue(validUpdateResponse);
  const updateWithNetworkErrors = jest.fn().mockRejectedValue(sentryError);
  const updateWithErrors = jest.fn().mockResolvedValue(errorUpdateResponse);

  const findAlert = () => wrapper.find(GlAlert);
  const findLoadingIcon = () => wrapper.find(GlLoadingIcon);
  const findForm = () => wrapper.find(GlForm);
  const findNameInputGroup = () => wrapper.find('[data-testid="name-input-group"]');
  const findNameInput = () => wrapper.find('[data-testid="name-input"]');
  const findDescriptionInput = () => wrapper.find('[data-testid="description-input"]');
  const findColorPicker = () => wrapper.find(ColorPicker);
  const findSubmitBtn = () => wrapper.find('[data-testid="submit-btn"]');
  const findCancelBtn = () => wrapper.find('[data-testid="cancel-btn"]');

  function createMockApolloProvider(requestHandlers) {
    localVue.use(VueApollo);

    return createMockApollo(requestHandlers);
  }

  function createComponent(props = {}, mountFn = mount) {
    return mountFn(Form, {
      localVue,
      apolloProvider: createMockApollo([]),
      propsData: {
        ...defaultPropsData,
        ...props,
      },
      stubs: {
        GlLoadingIcon,
      },
    });
  }

  function createComponentWithApollo(requestHandlers = [], props = {}, mountFn = mount) {
    return mountFn(Form, {
      localVue,
      apolloProvider: createMockApolloProvider(requestHandlers),
      propsData: {
        ...defaultPropsData,
        ...props,
      },
      stubs: {
        GlLoadingIcon,
      },
    });
  }

  beforeEach(() => {
    gon.suggested_label_colors = {
      '#000000': 'Black',
      '#0033CC': 'UA blue',
      '#428BCA': 'Moderate blue',
      '#44AD8E': 'Lime green',
    };
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('loading', () => {
    beforeEach(() => {
      wrapper = createComponentWithApollo(
        [[getComplianceFrameworkQuery, fetchLoading]],
        {
          id: '1',
        },
        shallowMount,
      );
    });

    it('shows the loader', () => {
      expect(findLoadingIcon().exists()).toBe(true);
    });

    it('does not show the other parts of the app', () => {
      expect(findAlert().exists()).toBe(false);
      expect(findForm().exists()).toBe(false);
    });
  });

  describe('display inputs', () => {
    it('shows the correct input and button fields', () => {
      wrapper = createComponent({}, shallowMount);

      expect(findLoadingIcon().exists()).toBe(false);
      expect(findNameInput).toExist();
      expect(findDescriptionInput).toExist();
      expect(findColorPicker).toExist();
      expect(findSubmitBtn).toExist();
      expect(findCancelBtn).toExist();
    });

    it('shows the name input description', () => {
      wrapper = createComponent();

      expect(findNameInputGroup().text()).toContain('Use :: to create a scoped set (eg. SOX::AWS)');
    });

    it('shows the name validation if there is no title', async () => {
      wrapper = createComponent();
      const nameInput = findNameInput();

      await nameInput.setValue('Test');
      await nameInput.setValue('');

      expect(findNameInputGroup().text()).toContain('A title is required');
    });
  });

  describe('new framework', () => {
    const creationProps = {
      input: {
        namespacePath: 'group-1',
        params: {
          color: '#1aaa55',
          description: 'General Data Protection Regulation',
          name: 'GDPR',
        },
      },
    };

    const setFields = async () => {
      await findNameInput().setValue(creationProps.input.params.name);
      await findDescriptionInput().setValue(creationProps.input.params.description);
      await findColorPicker().find(GlFormInput).setValue(creationProps.input.params.color);

      await findForm().trigger('submit');
    };

    it('does not query for existing framework data', async () => {
      wrapper = createComponentWithApollo([[getComplianceFrameworkQuery, fetch]], {}, shallowMount);

      await waitForPromises();

      expect(findLoadingIcon().exists()).toBe(false);
      expect(fetch).not.toHaveBeenCalled();
    });

    it('saves inputted values and redirects', async () => {
      wrapper = createComponentWithApollo([[createComplianceFrameworkMutation, create]]);

      await setFields();
      await waitForPromises();

      expect(findLoadingIcon().exists()).toBe(false);
      expect(create).toHaveBeenCalledWith(creationProps);
      expect(visitUrl).toHaveBeenCalledWith(defaultPropsData.groupEditPath);
    });

    it('shows an error when saving fails and does not redirect', async () => {
      jest.spyOn(Sentry, 'captureException');
      wrapper = createComponentWithApollo([[createComplianceFrameworkMutation, createWithErrors]]);

      await setFields();
      await waitForPromises();

      expect(findLoadingIcon().exists()).toBe(false);
      expect(createWithErrors).toHaveBeenCalledWith(creationProps);
      expect(visitUrl).not.toHaveBeenCalled();
      expect(findAlert().text()).toBe('Invalid values given');
      expect(Sentry.captureException.mock.calls[0][0]).toStrictEqual(sentrySaveError);
    });

    it('shows an error when saving causes an exception and does not redirect', async () => {
      jest.spyOn(Sentry, 'captureException');
      wrapper = createComponentWithApollo([
        [createComplianceFrameworkMutation, createWithNetworkErrors],
      ]);

      await setFields();
      await waitForPromises();

      expect(findLoadingIcon().exists()).toBe(false);
      expect(createWithNetworkErrors).toHaveBeenCalledWith(creationProps);
      expect(visitUrl).not.toHaveBeenCalled();
      expect(findAlert().text()).toBe('Unable to save this compliance framework. Please try again');
      expect(Sentry.captureException.mock.calls[0][0].networkError).toBe(sentryError);
    });
  });

  describe('edit framework', () => {
    const updateProps = {
      input: {
        namespacePath: 'group-1',
        params: {
          color: '#000000',
          description: 'Test description',
          name: 'Test',
        },
      },
    };

    const setFields = async () => {
      await findNameInput().setValue(updateProps.input.params.name);
      await findDescriptionInput().setValue(updateProps.input.params.description);
      await findColorPicker().find(GlFormInput).setValue(updateProps.input.params.color);

      await findForm().trigger('submit');
    };

    it('queries for existing framework data and sets the correct values in the input fields', async () => {
      wrapper = createComponentWithApollo(
        [[getComplianceFrameworkQuery, fetchOne]],
        { id: '1' },
        shallowMount,
      );

      await waitForPromises();

      expect(findLoadingIcon().exists()).toBe(false);
      expect(fetchOne).toHaveBeenCalledTimes(1);
      expect(findNameInput().attributes('value')).toBe('GDPR');
      expect(findDescriptionInput().attributes('value')).toBe('General Data Protection Regulation');
      expect(findColorPicker().attributes('value')).toBe('#1aaa55');
    });

    it('shows an error if the existing framework query returns no data', async () => {
      jest.spyOn(Sentry, 'captureException');
      wrapper = createComponentWithApollo(
        [[getComplianceFrameworkQuery, fetchEmpty]],
        { id: '1' },
        shallowMount,
      );

      await waitForPromises();

      expect(findLoadingIcon().exists()).toBe(false);
      expect(fetchEmpty).toHaveBeenCalledTimes(1);
      expect(findAlert().text()).toBe(
        'Error fetching compliance frameworks data. Please refresh the page',
      );
      expect(Sentry.captureException.mock.calls[0][0]).toStrictEqual(
        new Error(
          'Unknown compliance framework given. Please try a different framework or refresh the page',
        ),
      );
    });

    it('shows an error if the existing framework query fails', async () => {
      jest.spyOn(Sentry, 'captureException');
      wrapper = createComponentWithApollo(
        [[getComplianceFrameworkQuery, fetchWithErrors]],
        {
          id: '1',
        },
        shallowMount,
      );

      await waitForPromises();

      expect(findLoadingIcon().exists()).toBe(false);
      expect(fetchWithErrors).toHaveBeenCalledTimes(1);
      expect(findAlert().text()).toBe(
        'Error fetching compliance frameworks data. Please refresh the page',
      );
      expect(Sentry.captureException.mock.calls[0][0].networkError).toBe(sentryError);
    });

    it('saves inputted values and redirects', async () => {
      wrapper = createComponentWithApollo([[updateComplianceFrameworkMutation, update]], {
        id: '1',
      });

      await setFields();
      await waitForPromises();

      expect(findLoadingIcon().exists()).toBe(false);
      expect(update).toHaveBeenCalledWith(updateProps);
      expect(visitUrl).toHaveBeenCalledWith(defaultPropsData.groupEditPath);
    });

    it('shows an error when saving fails and does not redirect', async () => {
      jest.spyOn(Sentry, 'captureException');
      wrapper = createComponentWithApollo([[updateComplianceFrameworkMutation, updateWithErrors]]);

      await setFields();
      await waitForPromises();

      expect(findLoadingIcon().exists()).toBe(false);
      expect(updateWithErrors).toHaveBeenCalledWith(updateProps);
      expect(visitUrl).not.toHaveBeenCalled();
      expect(findAlert().text()).toBe('Invalid values given');
      expect(Sentry.captureException.mock.calls[0][0]).toStrictEqual(sentrySaveError);
    });

    it('shows an error when saving causes an exception and does not redirect', async () => {
      jest.spyOn(Sentry, 'captureException');
      wrapper = createComponentWithApollo([
        [updateComplianceFrameworkMutation, updateWithNetworkErrors],
      ]);

      await setFields();
      await waitForPromises();

      expect(findLoadingIcon().exists()).toBe(false);
      expect(updateWithNetworkErrors).toHaveBeenCalledWith(updateProps);
      expect(visitUrl).not.toHaveBeenCalled();
      expect(findAlert().text()).toBe('Unable to save this compliance framework. Please try again');
      expect(Sentry.captureException.mock.calls[0][0].networkError).toBe(sentryError);
    });
  });
});
