import * as Sentry from '@sentry/browser';
import AxiosMockAdapter from 'axios-mock-adapter';
import { GlAlert } from '@gitlab/ui';
import axios from '~/lib/utils/axios_utils';
import { redirectTo } from '~/lib/utils/url_utility';
import waitForPromises from 'helpers/wait_for_promises';
import { shallowMount } from '@vue/test-utils';
import ConfigurationForm from 'ee/security_configuration/sast/components/configuration_form.vue';
import DynamicFields from 'ee/security_configuration/sast/components/dynamic_fields.vue';
import { makeEntities } from './helpers';

jest.mock('~/lib/utils/url_utility', () => ({
  redirectTo: jest.fn(),
}));

const createSastMergeRequestPath = '/merge_request/create';
const securityConfigurationPath = '/security/configuration';
const newMergeRequestPath = '/merge_request/new';

describe('ConfigurationForm component', () => {
  let wrapper;
  let entities;
  let axiosMock;

  const createComponent = ({ props = {} } = {}) => {
    entities = makeEntities(3, { value: 'foo' });

    wrapper = shallowMount(ConfigurationForm, {
      provide: {
        createSastMergeRequestPath,
        securityConfigurationPath,
      },
      propsData: {
        entities,
        ...props,
      },
    });
  };

  const findForm = () => wrapper.find('form');
  const findSubmitButton = () => wrapper.find({ ref: 'submitButton' });
  const findErrorAlert = () => wrapper.find(GlAlert);
  const findCancelButton = () => wrapper.find({ ref: 'cancelButton' });
  const findDynamicFieldsComponent = () => wrapper.find(DynamicFields);

  const expectPayloadForEntities = () => {
    const { post } = axiosMock.history;

    expect(post).toHaveLength(1);

    const postedData = JSON.parse(post[0].data);
    entities.forEach(entity => {
      expect(postedData[entity.field]).toBe(entity.value);
    });
  };

  beforeEach(() => {
    axiosMock = new AxiosMockAdapter(axios);
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
    axiosMock.restore();
  });

  describe('the DynamicFields component', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders', () => {
      expect(findDynamicFieldsComponent().exists()).toBe(true);
    });

    it('recieves a copy of the entities prop', () => {
      const entitiesProp = findDynamicFieldsComponent().props('entities');

      expect(entitiesProp).not.toBe(entities);
      expect(entitiesProp).toEqual(entities);
    });

    describe('when the dynamic fields component emits an input event', () => {
      let dynamicFields;
      let newEntities;

      beforeEach(() => {
        dynamicFields = findDynamicFieldsComponent();
        newEntities = makeEntities(3, { value: 'foo' });
        dynamicFields.vm.$emit(DynamicFields.model.event, newEntities);
      });

      it('updates the entities binding', () => {
        expect(dynamicFields.props('entities')).toBe(newEntities);
      });
    });
  });

  describe('when submitting the form', () => {
    beforeEach(() => {
      jest.spyOn(Sentry, 'captureException').mockImplementation();
    });

    describe.each`
      context                    | filePath               | statusCode | partialErrorMessage
      ${'a response error code'} | ${newMergeRequestPath} | ${500}     | ${'500'}
      ${'no filePath'}           | ${''}                  | ${200}     | ${/merge request.*fail/}
    `(
      'given an unsuccessful endpoint response due to $context',
      ({ filePath, statusCode, partialErrorMessage }) => {
        beforeEach(() => {
          axiosMock.onPost(createSastMergeRequestPath).replyOnce(statusCode, { filePath });
          createComponent();

          findForm().trigger('submit');
        });

        it('includes the value of each entity in the payload', expectPayloadForEntities);

        it(`sets the submit button's loading prop to true`, () => {
          expect(findSubmitButton().props('loading')).toBe(true);
        });

        describe('after async tasks', () => {
          beforeEach(() => waitForPromises());

          it('does not call redirectTo', () => {
            expect(redirectTo).not.toHaveBeenCalled();
          });

          it('displays an alert message', () => {
            expect(findErrorAlert().exists()).toBe(true);
          });

          it('sends the error to Sentry', () => {
            expect(Sentry.captureException.mock.calls).toMatchObject([
              [{ message: expect.stringMatching(partialErrorMessage) }],
            ]);
          });

          it(`sets the submit button's loading prop to false`, () => {
            expect(findSubmitButton().props('loading')).toBe(false);
          });

          describe('submitting again after a previous error', () => {
            beforeEach(() => {
              findForm().trigger('submit');
            });

            it('hides the alert message', () => {
              expect(findErrorAlert().exists()).toBe(false);
            });
          });
        });
      },
    );

    describe('given a successful endpoint response', () => {
      beforeEach(() => {
        axiosMock
          .onPost(createSastMergeRequestPath)
          .replyOnce(200, { filePath: newMergeRequestPath });
        createComponent();

        findForm().trigger('submit');
      });

      it('includes the value of each entity in the payload', expectPayloadForEntities);

      it(`sets the submit button's loading prop to true`, () => {
        expect(findSubmitButton().props().loading).toBe(true);
      });

      describe('after async tasks', () => {
        beforeEach(() => waitForPromises());

        it('calls redirectTo', () => {
          expect(redirectTo).toHaveBeenCalledWith(newMergeRequestPath);
        });

        it('does not display an alert message', () => {
          expect(findErrorAlert().exists()).toBe(false);
        });

        it('does not call Sentry.captureException', () => {
          expect(Sentry.captureException).not.toHaveBeenCalled();
        });

        it('keeps the loading prop set to true', () => {
          // This is done for UX reasons. If the loading prop is set to false
          // on success, then there's a period where the button is clickable
          // again. Instead, we want the button to display a loading indicator
          // for the remainder of the lifetime of the page (i.e., until the
          // browser can start painting the new page it's been redirected to).
          expect(findSubmitButton().props().loading).toBe(true);
        });
      });
    });
  });

  describe('the cancel button', () => {
    beforeEach(() => {
      createComponent();
    });

    it('exists', () => {
      expect(findCancelButton().exists()).toBe(true);
    });

    it('links to the Security Configuration page', () => {
      expect(findCancelButton().attributes('href')).toBe(securityConfigurationPath);
    });
  });
});
