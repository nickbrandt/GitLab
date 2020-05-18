import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import {
  STEPS,
  SUBSCRIPTON_FLOW_STEPS,
  ONBOARDING_ISSUES_EXPERIMENT_AND_SUBSCRIPTION_FLOW_STEPS,
} from 'ee/registrations/constants';
import ProgressBar from 'ee/registrations/components/progress_bar.vue';

export default () => {
  const el = document.getElementById('progress-bar');

  if (!el) return null;

  const isOnboardingIssuesExperimentEnabled = parseBoolean(
    el.dataset.isOnboardingIssuesExperimentEnabled,
  );

  const steps = isOnboardingIssuesExperimentEnabled
    ? ONBOARDING_ISSUES_EXPERIMENT_AND_SUBSCRIPTION_FLOW_STEPS
    : SUBSCRIPTON_FLOW_STEPS;

  return new Vue({
    el,
    render(createElement) {
      return createElement(ProgressBar, {
        props: { steps, currentStep: STEPS.yourGroup },
      });
    },
  });
};
