import Vue from 'vue';
import WelcomePage from './components/welcome_page.vue';

export default function() {
  const el = document.getElementById('js-onboarding-welcome');

  if (!el) {
    return false;
  }

  const { userAvatarUrl, projectFullPath, skipUrl } = el.dataset;

  return new Vue({
    el,
    render(h) {
      return h(WelcomePage, {
        props: {
          userAvatarUrl,
          projectFullPath,
          skipUrl,
        },
      });
    },
  });
}
