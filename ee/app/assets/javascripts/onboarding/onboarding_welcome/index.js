import Vue from 'vue';
import WelcomePage from './components/welcome_page.vue';
import { parseBoolean } from '~/lib/utils/common_utils';

export default function() {
  const el = document.getElementById('js-onboarding-welcome');

  if (!el) {
    return false;
  }

  const { userAvatarUrl, projectFullPath, skipUrl, fromHelpMenu } = el.dataset;

  return new Vue({
    el,
    render(h) {
      return h(WelcomePage, {
        props: {
          userAvatarUrl,
          projectFullPath,
          skipUrl,
          fromHelpMenu: parseBoolean(fromHelpMenu),
        },
      });
    },
  });
}
