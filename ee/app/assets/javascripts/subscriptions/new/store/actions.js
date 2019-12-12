import * as types from './mutation_types';
import axios from '~/lib/utils/axios_utils';
import { s__ } from '~/locale';
import createFlash from '~/flash';
import { STEPS, COUNTRIES_URL, STATES_URL } from '../constants';

export const activateStep = ({ commit }, currentStep) => {
  if (STEPS.includes(currentStep)) {
    commit(types.UPDATE_CURRENT_STEP, currentStep);
  }
};

export const activateNextStep = ({ commit, getters }) => {
  const { currentStepIndex } = getters;

  if (currentStepIndex < STEPS.length - 1) {
    const nextStep = STEPS[currentStepIndex + 1];

    commit(types.UPDATE_CURRENT_STEP, nextStep);
  }
};

export const updateSelectedPlan = ({ commit }, selectedPlan) => {
  commit(types.UPDATE_SELECTED_PLAN, selectedPlan);
};

export const toggleIsSetupForCompany = ({ state, commit }) => {
  commit(types.UPDATE_IS_SETUP_FOR_COMPANY, !state.isSetupForCompany);
};

export const updateNumberOfUsers = ({ commit }, numberOfUsers) => {
  commit(types.UPDATE_NUMBER_OF_USERS, numberOfUsers || 0);
};

export const updateOrganizationName = ({ commit }, organizationName) => {
  commit(types.UPDATE_ORGANIZATION_NAME, organizationName);
};

export const fetchCountries = ({ dispatch }) => {
  axios
    .get(COUNTRIES_URL)
    .then(({ data }) => dispatch('fetchCountriesSuccess', data))
    .catch(() => dispatch('fetchCountriesError'));
};

export const fetchCountriesSuccess = ({ commit }, data = []) => {
  const countries = data.map(country => ({ text: country[0], value: country[1] }));

  commit(types.UPDATE_COUNTRY_OPTIONS, countries);
};

export const fetchCountriesError = () => {
  createFlash(s__('Checkout|Failed to load countries. Please try again.'));
};

export const fetchStates = ({ state, dispatch }) => {
  dispatch('resetStates');

  if (!state.country) {
    return;
  }

  axios
    .get(STATES_URL, { params: { country: state.country } })
    .then(({ data }) => dispatch('fetchStatesSuccess', data))
    .catch(() => dispatch('fetchStatesError'));
};

export const fetchStatesSuccess = ({ commit }, data = {}) => {
  const states = Object.keys(data).map(state => ({ text: state, value: data[state] }));

  commit(types.UPDATE_STATE_OPTIONS, states);
};

export const fetchStatesError = () => {
  createFlash(s__('Checkout|Failed to load states. Please try again.'));
};

export const resetStates = ({ commit }) => {
  commit(types.UPDATE_COUNTRY_STATE, null);
  commit(types.UPDATE_STATE_OPTIONS, []);
};

export const updateCountry = ({ commit }, country) => {
  commit(types.UPDATE_COUNTRY, country);
};

export const updateStreetAddressLine1 = ({ commit }, streetAddressLine1) => {
  commit(types.UPDATE_STREET_ADDRESS_LINE_ONE, streetAddressLine1);
};

export const updateStreetAddressLine2 = ({ commit }, streetAddressLine2) => {
  commit(types.UPDATE_STREET_ADDRESS_LINE_TWO, streetAddressLine2);
};

export const updateCity = ({ commit }, city) => {
  commit(types.UPDATE_CITY, city);
};

export const updateCountryState = ({ commit }, countryState) => {
  commit(types.UPDATE_COUNTRY_STATE, countryState);
};

export const updateZipCode = ({ commit }, zipCode) => {
  commit(types.UPDATE_ZIP_CODE, zipCode);
};
