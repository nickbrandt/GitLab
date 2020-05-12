import Vue from 'vue';
import { STEPS } from '../constants';
import ProgressBar from '../components/progress_bar.vue';

export default () => {
  const el = document.getElementById('progress-bar');

  if (!el) return null;

  const steps = [STEPS.yourProfile, STEPS.yourGroup, STEPS.yourProject];

  return new Vue({
    el,
    render(createElement) {
      return createElement(ProgressBar, {
        props: { steps, currentStep: STEPS.yourProfile },
      });
    },
  });
};
