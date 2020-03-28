import Vue from 'vue';
import { PROGRESS_STEPS } from 'ee/subscriptions/new/constants';
import ProgressBar from 'ee/subscriptions/new/components/checkout/progress_bar.vue';

export default () => {
  const progressBarEl = document.getElementById('progress-bar');

  return new Vue({
    el: progressBarEl,
    render(createElement) {
      return createElement(ProgressBar, { props: { step: PROGRESS_STEPS.editGroup } });
    },
  });
};
