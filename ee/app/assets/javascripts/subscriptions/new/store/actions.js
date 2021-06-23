import Api from 'ee/api';
import { PAYMENT_FORM_ID } from 'ee/subscriptions/constants';
import { GENERAL_ERROR_MESSAGE } from 'ee/vue_shared/purchase_flow/constants';
import activateNextStepMutation from 'ee/vue_shared/purchase_flow/graphql/mutations/activate_next_step.mutation.graphql';
import createFlash from '~/flash';
import { redirectTo } from '~/lib/utils/url_utility';
import { sprintf, s__ } from '~/locale';
import defaultClient from '../graphql';
import * as types from './mutation_types';

export const updateSelectedPlan = ({ commit }, selectedPlan) => {
  commit(types.UPDATE_SELECTED_PLAN, selectedPlan);
};

export const updateSelectedGroup = ({ commit, getters }, selectedGroup) => {
  commit(types.UPDATE_SELECTED_GROUP, selectedGroup);
  commit(types.UPDATE_ORGANIZATION_NAME, null);
  commit(types.UPDATE_NUMBER_OF_USERS, getters.selectedGroupUsers);
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

export const fetchCountries = ({ dispatch }) =>
  Api.fetchCountries()
    .then(({ data }) => dispatch('fetchCountriesSuccess', data))
    .catch(() => dispatch('fetchCountriesError'));

export const fetchCountriesSuccess = ({ commit }, data = []) => {
  const countries = data.map((country) => ({ text: country[0], value: country[1] }));

  commit(types.UPDATE_COUNTRY_OPTIONS, countries);
};

export const fetchCountriesError = () => {
  createFlash({
    message: s__('Checkout|Failed to load countries. Please try again.'),
  });
};

export const fetchStates = ({ state, dispatch }) => {
  dispatch('resetStates');

  if (!state.country) {
    return;
  }

  Api.fetchStates(state.country)
    .then(({ data }) => dispatch('fetchStatesSuccess', data))
    .catch(() => dispatch('fetchStatesError'));
};

export const fetchStatesSuccess = ({ commit }, data = {}) => {
  const states = Object.keys(data).map((state) => ({ text: state, value: data[state] }));

  commit(types.UPDATE_STATE_OPTIONS, states);
};

export const fetchStatesError = () => {
  createFlash({
    message: s__('Checkout|Failed to load states. Please try again.'),
  });
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

export const startLoadingZuoraScript = ({ commit }) =>
  commit(types.UPDATE_IS_LOADING_PAYMENT_METHOD, true);

export const fetchPaymentFormParams = ({ dispatch }) =>
  Api.fetchPaymentFormParams(PAYMENT_FORM_ID)
    .then(({ data }) => dispatch('fetchPaymentFormParamsSuccess', data))
    .catch(() => dispatch('fetchPaymentFormParamsError'));

export const fetchPaymentFormParamsSuccess = ({ commit }, data) => {
  if (data.errors) {
    createFlash({
      message: sprintf(
        s__('Checkout|Credit card form failed to load: %{message}'),
        {
          message: data.errors,
        },
        false,
      ),
    });
  } else {
    commit(types.UPDATE_PAYMENT_FORM_PARAMS, data);
  }
};

export const fetchPaymentFormParamsError = () => {
  createFlash({
    message: s__('Checkout|Credit card form failed to load. Please try again.'),
  });
};

export const zuoraIframeRendered = ({ commit }) =>
  commit(types.UPDATE_IS_LOADING_PAYMENT_METHOD, false);

export const paymentFormSubmitted = ({ dispatch, commit }, response) => {
  if (response.success) {
    commit(types.UPDATE_IS_LOADING_PAYMENT_METHOD, true);

    dispatch('paymentFormSubmittedSuccess', response.refId);
  } else {
    dispatch('paymentFormSubmittedError', response);
  }
};

export const paymentFormSubmittedSuccess = ({ commit, dispatch }, paymentMethodId) => {
  commit(types.UPDATE_PAYMENT_METHOD_ID, paymentMethodId);

  dispatch('fetchPaymentMethodDetails');
};

export const paymentFormSubmittedError = (_, response) => {
  createFlash({
    message: sprintf(
      s__(
        'Checkout|Submitting the credit card form failed with code %{errorCode}: %{errorMessage}',
      ),
      response,
      false,
    ),
  });
};

export const fetchPaymentMethodDetails = ({ state, dispatch, commit }) =>
  Api.fetchPaymentMethodDetails(state.paymentMethodId)
    .then(({ data }) => dispatch('fetchPaymentMethodDetailsSuccess', data))
    .catch(() => dispatch('fetchPaymentMethodDetailsError'))
    .finally(() => commit(types.UPDATE_IS_LOADING_PAYMENT_METHOD, false));

export const fetchPaymentMethodDetailsSuccess = ({ commit }, creditCardDetails) => {
  commit(types.UPDATE_CREDIT_CARD_DETAILS, creditCardDetails);

  defaultClient
    .mutate({
      mutation: activateNextStepMutation,
    })
    .catch((error) => {
      createFlash({ message: GENERAL_ERROR_MESSAGE, error, captureError: true });
    });
};

export const fetchPaymentMethodDetailsError = () => {
  createFlash({
    message: s__('Checkout|Failed to register credit card. Please try again.'),
  });
};

export const confirmOrder = ({ getters, dispatch, commit }) => {
  commit(types.UPDATE_IS_CONFIRMING_ORDER, true);

  Api.confirmOrder(getters.confirmOrderParams)
    .then(({ data }) => {
      if (data.location) {
        dispatch('confirmOrderSuccess', {
          location: data.location,
        });
      } else {
        dispatch('confirmOrderError', JSON.stringify(data.errors));
      }
    })
    .catch(() => dispatch('confirmOrderError'));
};

export const confirmOrderSuccess = (_, { location }) => {
  redirectTo(location);
};

export const confirmOrderError = ({ commit }, message = null) => {
  commit(types.UPDATE_IS_CONFIRMING_ORDER, false);

  const errorString = message
    ? s__('Checkout|Failed to confirm your order: %{message}. Please try again.')
    : s__('Checkout|Failed to confirm your order! Please try again.');

  createFlash({
    message: sprintf(errorString, { message }, false),
  });
};
