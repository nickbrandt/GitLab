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
});
