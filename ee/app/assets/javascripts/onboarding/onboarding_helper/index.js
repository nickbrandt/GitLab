import Vue from 'vue';
import { mapActions } from 'vuex';
import OnboardingApp from './components/app.vue';
import createStore from './store';
import onboardingUtils from '../utils';
import {
  TOUR_TITLES,
  FEEDBACK_CONTENT,
  EXIT_TOUR_CONTENT,
  DNT_EXIT_TOUR_CONTENT,
} from '../constants';
import TOUR_PARTS from '../tour_parts';

export default function() {
  const el = document.getElementById('js-onboarding-helper');

  if (!el) {
    return false;
  }

  const tourData = onboardingUtils.getOnboardingLocalStorageState();

  if (!tourData || onboardingUtils.isOnboardingDismissed()) {
    return false;
  }

  const { projectFullPath, projectName, goldenTanukiSvgPath } = el.dataset;
  const url = window.location.href;
  const { tourKey, lastStepIndex, createdProjectPath } = tourData;
  const store = createStore();

  return new Vue({
    el,
    store,
    components: {
      OnboardingApp,
    },
    created() {
      if (tourKey) {
        this.setInitialData({
          url,
          projectFullPath,
          projectName,
          tourData: TOUR_PARTS,
          tourKey,
          lastStepIndex,
          createdProjectPath,
        });
      }
    },
    methods: {
      ...mapActions(['setInitialData']),
    },
    render(h) {
      return h(OnboardingApp, {
        props: {
          tourTitles: TOUR_TITLES,
          exitTourContent: EXIT_TOUR_CONTENT,
          feedbackContent: FEEDBACK_CONTENT,
          dntExitTourContent: DNT_EXIT_TOUR_CONTENT,
          goldenTanukiSvgPath,
        },
      });
    },
  });
}
