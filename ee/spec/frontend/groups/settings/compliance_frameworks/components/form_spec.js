import { GlAlert, GlLoadingIcon, GlForm, GlFormInput } from '@gitlab/ui';
import { mount, shallowMount } from '@vue/test-utils';

import waitForPromises from 'helpers/wait_for_promises';

import Form from 'ee/groups/settings/compliance_frameworks/components/form.vue';
import ColorPicker from '~/vue_shared/components/color_picker/color_picker.vue';
import { visitUrl } from '~/lib/utils/url_utility';
import * as Sentry from '~/sentry/wrapper';
import { frameworkFoundResponse } from '../mock_data';

jest.mock('~/lib/utils/url_utility');

describe('Form', () => {
  let wrapper;
  const service = { getComplianceFramework: jest.fn(), putComplianceFramework: jest.fn() };
  const groupEditPath = 'group-1/edit';

  const networkErrorMessage = 'Network error';
  const networkError = new Error(networkErrorMessage);
  const saveErrorMessage = 'Unable to save this compliance framework. Please try again';
  const saveError = new Error(saveErrorMessage);

  const findAlert = () => wrapper.find(GlAlert);
  const findLoadingIcon = () => wrapper.find(GlLoadingIcon);
  const findForm = () => wrapper.find(GlForm);
  const findNameInputGroup = () => wrapper.find('[data-testid="name-input-group"]');
  const findNameInput = () => wrapper.find('[data-testid="name-input"]');
  const findDescriptionInput = () => wrapper.find('[data-testid="description-input"]');
  const findColorPicker = () => wrapper.find(ColorPicker);
  const findSubmitBtn = () => wrapper.find('[data-testid="submit-btn"]');
  const findCancelBtn = () => wrapper.find('[data-testid="cancel-btn"]');

  function createComponent(mountFn = mount) {
    return mountFn(Form, {
      propsData: {
        groupEditPath,
        service,
      },
      stubs: {
        GlLoadingIcon,
      },
    });
  }

  const setFields = async () => {
    await findNameInput().setValue(frameworkFoundResponse.name);
    await findDescriptionInput().setValue(frameworkFoundResponse.description);
    await findColorPicker().find(GlFormInput).setValue(frameworkFoundResponse.color);
  };

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
      service.getComplianceFramework.mockReturnValueOnce({});
    });

    it('shows the loader on load', () => {
      wrapper = createComponent(shallowMount);

      expect(findLoadingIcon().exists()).toBe(true);
      expect(findAlert().exists()).toBe(false);
      expect(findForm().exists()).toBe(false);
    });

    it('shows the loader on form submission', async () => {
      wrapper = createComponent();

      await waitForPromises();

      expect(findLoadingIcon().exists()).toBe(false);
      expect(findAlert().exists()).toBe(false);
      expect(findForm().exists()).toBe(true);

      await setFields();
      await findForm().trigger('submit');

      expect(findLoadingIcon().exists()).toBe(true);
      expect(findAlert().exists()).toBe(false);
      expect(findForm().exists()).toBe(false);
    });
  });

  describe('mount', () => {
    it('shows an error if the `service.getComplianceFramework()` call fails', async () => {
      jest.spyOn(Sentry, 'captureException');
      service.getComplianceFramework.mockImplementationOnce(() => {
        throw networkError;
      });
      wrapper = createComponent(shallowMount);

      await waitForPromises();

      expect(findLoadingIcon().exists()).toBe(false);
      expect(findAlert().text()).toBe(
        'Error fetching compliance frameworks data. Please refresh the page',
      );
      expect(Sentry.captureException.mock.calls[0][0]).toStrictEqual(networkError);
    });

    it('gets the existing compliance framework and sets the field values', async () => {
      service.getComplianceFramework.mockReturnValueOnce(frameworkFoundResponse);
      wrapper = createComponent(shallowMount);

      await waitForPromises();

      expect(findLoadingIcon().exists()).toBe(false);
      expect(findNameInput().attributes('value')).toBe(frameworkFoundResponse.name);
      expect(findDescriptionInput().attributes('value')).toBe(frameworkFoundResponse.description);
      expect(findColorPicker().attributes('value')).toBe(frameworkFoundResponse.color);
    });
  });

  describe('display inputs', () => {
    beforeEach(() => {
      service.getComplianceFramework.mockReturnValueOnce({});
    });

    it('shows the correct input and button fields', async () => {
      wrapper = createComponent(shallowMount);

      await waitForPromises();

      expect(findLoadingIcon().exists()).toBe(false);
      expect(findNameInput()).toExist();
      expect(findDescriptionInput()).toExist();
      expect(findColorPicker()).toExist();
      expect(findSubmitBtn()).toExist();
      expect(findCancelBtn()).toExist();
    });

    it('shows the name input description', async () => {
      wrapper = createComponent();

      await waitForPromises();

      expect(findNameInputGroup().text()).toContain('Use :: to create a scoped set (eg. SOX::AWS)');
    });

    it('shows the name validation if there is no title', async () => {
      wrapper = createComponent();
      await waitForPromises();

      const feedbackElement = findNameInputGroup().find('.invalid-feedback');

      expect(feedbackElement.classes()).not.toContain('d-block');
      expect(findSubmitBtn().attributes('disabled')).toBeUndefined();

      const nameInput = findNameInput();

      await nameInput.setValue('Test');
      await nameInput.setValue('');

      expect(feedbackElement.classes()).toContain('d-block');
      expect(findSubmitBtn().attributes('disabled')).toBe('disabled');
    });
  });

  describe('on submission', () => {
    beforeEach(() => {
      service.getComplianceFramework.mockReturnValueOnce({});
    });

    it('shows an error if the `service.putComplianceFramework()` call fails', async () => {
      service.putComplianceFramework.mockImplementationOnce(() => {
        throw saveError;
      });

      jest.spyOn(Sentry, 'captureException');
      wrapper = createComponent();

      await waitForPromises();
      await setFields();
      await findForm().trigger('submit');
      await waitForPromises();

      expect(findLoadingIcon().exists()).toBe(false);
      expect(visitUrl).not.toHaveBeenCalled();
      expect(findAlert().text()).toBe(`Error: ${saveErrorMessage}`);
      expect(Sentry.captureException.mock.calls[0][0]).toStrictEqual(saveError);
    });

    it('returns a successful service response and redirects the user', async () => {
      service.putComplianceFramework.mockReturnValueOnce({});

      wrapper = createComponent();

      await waitForPromises();
      await setFields();
      await findForm().trigger('submit');
      await waitForPromises();

      expect(service.putComplianceFramework).toHaveBeenCalledWith({
        name: frameworkFoundResponse.name,
        description: frameworkFoundResponse.description,
        color: frameworkFoundResponse.color,
      });
      expect(findLoadingIcon().exists()).toBe(false);
      expect(findAlert().exists()).toBe(false);
      expect(visitUrl).toHaveBeenCalledWith(groupEditPath);
    });
  });
});
