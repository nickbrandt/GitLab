import * as types from './mutation_types';
import { STEPS } from '../constants';

export const activateStep = ({ commit }, step) => {
  if (STEPS.includes(step)) {
    commit(types.ACTIVATE_STEP, step);
  }
};

export const activateNextStep = ({ commit, getters }) => {
  const { activeStepIndex } = getters;

  if (activeStepIndex < STEPS.length - 1) {
    const nextStep = STEPS[activeStepIndex + 1];

    commit(types.ACTIVATE_STEP, nextStep);
  }
};
