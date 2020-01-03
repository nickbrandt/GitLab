import { STEPS } from '../constants';

export const currentStep = state => state.currentStep;

export const stepIndex = () => step => STEPS.findIndex(el => el === step);

export const activeStepIndex = (state, getters) => getters.stepIndex(state.currentStep);
