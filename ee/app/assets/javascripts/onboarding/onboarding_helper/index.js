import Vue from 'vue';
import OnboardingApp from './components/app.vue';

export default function() {
  const el = document.getElementById('js-onboarding-helper');

  if (!el) {
    return false;
  }

  return new Vue({
    el,
    components: {
      OnboardingApp,
    },

    render(h) {
      return h(OnboardingApp, {
        props: {},
      });
    },
  });
}
