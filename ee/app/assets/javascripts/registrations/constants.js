import { s__ } from '~/locale';

export const STEPS = {
  yourProfile: s__('Registration|Your profile'),
  checkout: s__('Registration|Checkout'),
  yourGroup: s__('Registration|Your GitLab group'),
  yourProject: s__('Registration|Your first project'),
};

export const SUBSCRIPTON_FLOW_STEPS = [STEPS.yourProfile, STEPS.checkout, STEPS.yourGroup];

export const ONBOARDING_ISSUES_EXPERIMENT_FLOW_STEPS = [
  STEPS.yourProfile,
  STEPS.yourGroup,
  STEPS.yourProject,
];

export const ONBOARDING_ISSUES_EXPERIMENT_AND_SUBSCRIPTION_FLOW_STEPS = [
  STEPS.yourProfile,
  STEPS.checkout,
  STEPS.yourGroup,
  STEPS.yourProject,
];
