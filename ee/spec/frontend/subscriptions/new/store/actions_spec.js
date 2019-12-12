import testAction from 'helpers/vuex_action_helper';
import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import createFlash from '~/flash';
import * as actions from 'ee/subscriptions/new/store/actions';
import * as constants from 'ee/subscriptions/new/constants';

jest.mock('~/flash');

constants.STEPS = ['firstStep', 'secondStep'];

let mock;

describe('Subscriptions Actions', () => {
  describe('activateStep', () => {
    it('set the currentStep to the provided value', done => {
      testAction(
        actions.activateStep,
        'secondStep',
        {},
        [{ type: 'UPDATE_CURRENT_STEP', payload: 'secondStep' }],
        [],
        done,
      );
    });

    it('does not change the currentStep if provided value is not available', done => {
      testAction(actions.activateStep, 'thirdStep', {}, [], [], done);
    });
  });

  describe('activateNextStep', () => {
    it('set the currentStep to the next step in the available steps', done => {
      testAction(
        actions.activateNextStep,
        {},
        { currentStepIndex: 0 },
        [{ type: 'UPDATE_CURRENT_STEP', payload: 'secondStep' }],
        [],
        done,
      );
    });

    it('does not change the currentStep if the current step is the last step', done => {
      testAction(actions.activateNextStep, {}, { currentStepIndex: 1 }, [], [], done);
    });
  });

  describe('updateSelectedPlan', () => {
    it('updates the selected plan', done => {
      testAction(
        actions.updateSelectedPlan,
        'planId',
        {},
        [{ type: 'UPDATE_SELECTED_PLAN', payload: 'planId' }],
        [],
        done,
      );
    });
  });

  describe('toggleIsSetupForCompany', () => {
    it('toggles the isSetupForCompany value', done => {
      testAction(
        actions.toggleIsSetupForCompany,
        {},
        { isSetupForCompany: true },
        [{ type: 'UPDATE_IS_SETUP_FOR_COMPANY', payload: false }],
        [],
        done,
      );
    });
  });

  describe('updateNumberOfUsers', () => {
    it('updates numberOfUsers to 0 when no value is provided', done => {
      testAction(
        actions.updateNumberOfUsers,
        null,
        {},
        [{ type: 'UPDATE_NUMBER_OF_USERS', payload: 0 }],
        [],
        done,
      );
    });

    it('updates numberOfUsers when a value is provided', done => {
      testAction(
        actions.updateNumberOfUsers,
        2,
        {},
        [{ type: 'UPDATE_NUMBER_OF_USERS', payload: 2 }],
        [],
        done,
      );
    });
  });

  describe('updateOrganizationName', () => {
    it('updates organizationName to the provided value', done => {
      testAction(
        actions.updateOrganizationName,
        'name',
        {},
        [{ type: 'UPDATE_ORGANIZATION_NAME', payload: 'name' }],
        [],
        done,
      );
    });
  });

  describe('fetchCountries', () => {
    beforeEach(() => {
      mock = new MockAdapter(axios);
    });

    afterEach(() => {
      mock.restore();
    });

    it('calls fetchCountriesSuccess with the returned data on success', done => {
      mock.onGet(constants.COUNTRIES_URL).replyOnce(200, ['Netherlands', 'NL']);

      testAction(
        actions.fetchCountries,
        null,
        {},
        [],
        [{ type: 'fetchCountriesSuccess', payload: ['Netherlands', 'NL'] }],
        done,
      );
    });

    it('calls fetchCountriesError on error', done => {
      mock.onGet(constants.COUNTRIES_URL).replyOnce(500);

      testAction(actions.fetchCountries, null, {}, [], [{ type: 'fetchCountriesError' }], done);
    });
  });

  describe('fetchCountriesSuccess', () => {
    it('transforms and adds fetched countryOptions', done => {
      testAction(
        actions.fetchCountriesSuccess,
        [['Netherlands', 'NL']],
        {},
        [{ type: 'UPDATE_COUNTRY_OPTIONS', payload: [{ text: 'Netherlands', value: 'NL' }] }],
        [],
        done,
      );
    });

    it('adds an empty array when no data provided', done => {
      testAction(
        actions.fetchCountriesSuccess,
        undefined,
        {},
        [{ type: 'UPDATE_COUNTRY_OPTIONS', payload: [] }],
        [],
        done,
      );
    });
  });

  describe('fetchCountriesError', () => {
    it('creates a flash', done => {
      testAction(actions.fetchCountriesError, null, {}, [], [], () => {
        expect(createFlash).toHaveBeenCalledWith('Failed to load countries. Please try again.');
        done();
      });
    });
  });

  describe('fetchStates', () => {
    beforeEach(() => {
      mock = new MockAdapter(axios);
    });

    afterEach(() => {
      mock.restore();
    });

    it('calls resetStates and fetchStatesSuccess with the returned data on success', done => {
      mock
        .onGet(constants.STATES_URL, { params: { country: 'NL' } })
        .replyOnce(200, { utrecht: 'UT' });

      testAction(
        actions.fetchStates,
        null,
        { country: 'NL' },
        [],
        [{ type: 'resetStates' }, { type: 'fetchStatesSuccess', payload: { utrecht: 'UT' } }],
        done,
      );
    });

    it('only calls resetStates when no country selected', done => {
      mock.onGet(constants.STATES_URL).replyOnce(500);

      testAction(actions.fetchStates, null, { country: null }, [], [{ type: 'resetStates' }], done);
    });

    it('calls resetStates and fetchStatesError on error', done => {
      mock.onGet(constants.STATES_URL).replyOnce(500);

      testAction(
        actions.fetchStates,
        null,
        { country: 'NL' },
        [],
        [{ type: 'resetStates' }, { type: 'fetchStatesError' }],
        done,
      );
    });
  });

  describe('fetchStatesSuccess', () => {
    it('transforms and adds received stateOptions', done => {
      testAction(
        actions.fetchStatesSuccess,
        { Utrecht: 'UT' },
        {},
        [{ type: 'UPDATE_STATE_OPTIONS', payload: [{ text: 'Utrecht', value: 'UT' }] }],
        [],
        done,
      );
    });

    it('adds an empty array when no data provided', done => {
      testAction(
        actions.fetchStatesSuccess,
        undefined,
        {},
        [{ type: 'UPDATE_STATE_OPTIONS', payload: [] }],
        [],
        done,
      );
    });
  });

  describe('fetchStatesError', () => {
    it('creates a flash', done => {
      testAction(actions.fetchStatesError, null, {}, [], [], () => {
        expect(createFlash).toHaveBeenCalledWith('Failed to load states. Please try again.');
        done();
      });
    });
  });

  describe('resetStates', () => {
    it('resets the selected state and sets the stateOptions to the initial value', done => {
      testAction(
        actions.resetStates,
        null,
        {},
        [
          { type: 'UPDATE_COUNTRY_STATE', payload: null },
          { type: 'UPDATE_STATE_OPTIONS', payload: [] },
        ],
        [],
        done,
      );
    });
  });

  describe('updateCountry', () => {
    it('updates country to the provided value', done => {
      testAction(
        actions.updateCountry,
        'country',
        {},
        [{ type: 'UPDATE_COUNTRY', payload: 'country' }],
        [],
        done,
      );
    });
  });

  describe('updateStreetAddressLine1', () => {
    it('updates streetAddressLine1 to the provided value', done => {
      testAction(
        actions.updateStreetAddressLine1,
        'streetAddressLine1',
        {},
        [{ type: 'UPDATE_STREET_ADDRESS_LINE_ONE', payload: 'streetAddressLine1' }],
        [],
        done,
      );
    });
  });

  describe('updateStreetAddressLine2', () => {
    it('updates streetAddressLine2 to the provided value', done => {
      testAction(
        actions.updateStreetAddressLine2,
        'streetAddressLine2',
        {},
        [{ type: 'UPDATE_STREET_ADDRESS_LINE_TWO', payload: 'streetAddressLine2' }],
        [],
        done,
      );
    });
  });

  describe('updateCity', () => {
    it('updates city to the provided value', done => {
      testAction(
        actions.updateCity,
        'city',
        {},
        [{ type: 'UPDATE_CITY', payload: 'city' }],
        [],
        done,
      );
    });
  });

  describe('updateCountryState', () => {
    it('updates countryState to the provided value', done => {
      testAction(
        actions.updateCountryState,
        'countryState',
        {},
        [{ type: 'UPDATE_COUNTRY_STATE', payload: 'countryState' }],
        [],
        done,
      );
    });
  });

  describe('updateZipCode', () => {
    it('updates zipCode to the provided value', done => {
      testAction(
        actions.updateZipCode,
        'zipCode',
        {},
        [{ type: 'UPDATE_ZIP_CODE', payload: 'zipCode' }],
        [],
        done,
      );
    });
  });

  describe('fetchPaymentFormParams', () => {
    beforeEach(() => {
      mock = new MockAdapter(axios);
    });

    afterEach(() => {
      mock.restore();
    });

    it('fetches paymentFormParams and calls fetchPaymentFormParamsSuccess with the returned data on success', done => {
      mock
        .onGet(constants.PAYMENT_FORM_URL, { params: { id: constants.PAYMENT_FORM_ID } })
        .replyOnce(200, { token: 'x' });

      testAction(
        actions.fetchPaymentFormParams,
        null,
        {},
        [],
        [{ type: 'fetchPaymentFormParamsSuccess', payload: { token: 'x' } }],
        done,
      );
    });

    it('calls fetchPaymentFormParamsError on error', done => {
      mock.onGet(constants.PAYMENT_FORM_URL).replyOnce(500);

      testAction(
        actions.fetchPaymentFormParams,
        null,
        {},
        [],
        [{ type: 'fetchPaymentFormParamsError' }],
        done,
      );
    });
  });

  describe('fetchPaymentFormParamsSuccess', () => {
    it('updates paymentFormParams to the provided value when no errors are present', done => {
      testAction(
        actions.fetchPaymentFormParamsSuccess,
        { token: 'x' },
        {},
        [{ type: 'UPDATE_PAYMENT_FORM_PARAMS', payload: { token: 'x' } }],
        [],
        done,
      );
    });

    it('creates a flash when errors are present', done => {
      testAction(
        actions.fetchPaymentFormParamsSuccess,
        { errors: 'error message' },
        {},
        [],
        [],
        () => {
          expect(createFlash).toHaveBeenCalledWith(
            'Credit card form failed to load: error message',
          );
          done();
        },
      );
    });
  });

  describe('fetchPaymentFormParamsError', () => {
    it('creates a flash', done => {
      testAction(actions.fetchPaymentFormParamsError, null, {}, [], [], () => {
        expect(createFlash).toHaveBeenCalledWith(
          'Credit card form failed to load. Please try again.',
        );
        done();
      });
    });
  });

  describe('paymentFormSubmitted', () => {
    describe('on success', () => {
      it('calls paymentFormSubmittedSuccess with the refID from the response', done => {
        testAction(
          actions.paymentFormSubmitted,
          { success: true, refId: 'id' },
          {},
          [],
          [{ type: 'paymentFormSubmittedSuccess', payload: 'id' }],
          done,
        );
      });
    });

    describe('on failure', () => {
      it('calls paymentFormSubmittedError with the response', done => {
        testAction(
          actions.paymentFormSubmitted,
          { error: 'foo' },
          {},
          [],
          [{ type: 'paymentFormSubmittedError', payload: { error: 'foo' } }],
          done,
        );
      });
    });
  });

  describe('paymentFormSubmittedSuccess', () => {
    it('updates paymentMethodId to the provided value and calls fetchPaymentMethodDetails', done => {
      testAction(
        actions.paymentFormSubmittedSuccess,
        'id',
        {},
        [{ type: 'UPDATE_PAYMENT_METHOD_ID', payload: 'id' }],
        [{ type: 'fetchPaymentMethodDetails' }],
        done,
      );
    });
  });

  describe('paymentFormSubmittedError', () => {
    it('creates a flash', done => {
      testAction(
        actions.paymentFormSubmittedError,
        { errorCode: 'codeFromResponse', errorMessage: 'messageFromResponse' },
        {},
        [],
        [],
        () => {
          expect(createFlash).toHaveBeenCalledWith(
            'Submitting the credit card form failed with code codeFromResponse: messageFromResponse',
          );
          done();
        },
      );
    });
  });

  describe('fetchPaymentMethodDetails', () => {
    beforeEach(() => {
      mock = new MockAdapter(axios);
    });

    afterEach(() => {
      mock.restore();
    });

    it('fetches paymentMethodDetails and calls fetchPaymentMethodDetailsSuccess with the returned data on success', done => {
      mock
        .onGet(constants.PAYMENT_METHOD_URL, { params: { id: 'paymentMethodId' } })
        .replyOnce(200, { token: 'x' });

      testAction(
        actions.fetchPaymentMethodDetails,
        null,
        { paymentMethodId: 'paymentMethodId' },
        [],
        [{ type: 'fetchPaymentMethodDetailsSuccess', payload: { token: 'x' } }],
        done,
      );
    });

    it('calls fetchPaymentMethodDetailsError on error', done => {
      mock.onGet(constants.PAYMENT_METHOD_URL).replyOnce(500);

      testAction(
        actions.fetchPaymentMethodDetails,
        null,
        {},
        [],
        [{ type: 'fetchPaymentMethodDetailsError' }],
        done,
      );
    });
  });

  describe('fetchPaymentMethodDetailsSuccess', () => {
    it('updates creditCardDetails to the provided data and calls activateNextStep', done => {
      testAction(
        actions.fetchPaymentMethodDetailsSuccess,
        {
          credit_card_type: 'cc_type',
          credit_card_mask_number: '4242424242424242',
          credit_card_expiration_month: 12,
          credit_card_expiration_year: 2019,
        },
        {},
        [
          {
            type: 'UPDATE_CREDIT_CARD_DETAILS',
            payload: {
              cardType: 'cc_type',
              lastFourDigits: '4242',
              expirationMonth: 12,
              expirationYear: 19,
            },
          },
        ],
        [{ type: 'activateNextStep' }],
        done,
      );
    });
  });

  describe('fetchPaymentMethodDetailsError', () => {
    it('creates a flash', done => {
      testAction(actions.fetchPaymentMethodDetailsError, null, {}, [], [], () => {
        expect(createFlash).toHaveBeenCalledWith(
          'Failed to register credit card. Please try again.',
        );
        done();
      });
    });
  });
});
