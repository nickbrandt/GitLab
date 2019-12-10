import * as types from './mutation_types';
import { STEPS } from '../constants';

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
