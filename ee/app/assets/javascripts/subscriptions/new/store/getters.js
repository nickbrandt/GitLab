import { STEPS } from '../constants';

export const currentStep = state => state.currentStep;

export const stepIndex = () => step => STEPS.findIndex(el => el === step);

export const currentStepIndex = (state, getters) => getters.stepIndex(state.currentStep);

export const selectedPlanText = (state, getters) => getters.selectedPlanDetails.text;

export const selectedPlanDetails = state =>
  state.availablePlans.find(plan => plan.value === state.selectedPlan);
