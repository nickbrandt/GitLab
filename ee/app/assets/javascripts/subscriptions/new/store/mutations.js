import * as types from './mutation_types';

export default {
  [types.UPDATE_CURRENT_STEP](state, currentStep) {
    state.currentStep = currentStep;
  },

  [types.UPDATE_SELECTED_PLAN](state, selectedPlan) {
    state.selectedPlan = selectedPlan;
  },

  [types.UPDATE_IS_SETUP_FOR_COMPANY](state, isSetupForCompany) {
    state.isSetupForCompany = isSetupForCompany;
  },

  [types.UPDATE_NUMBER_OF_USERS](state, numberOfUsers) {
    state.numberOfUsers = numberOfUsers;
  },

  [types.UPDATE_ORGANIZATION_NAME](state, organizationName) {
    state.organizationName = organizationName;
  },
};
