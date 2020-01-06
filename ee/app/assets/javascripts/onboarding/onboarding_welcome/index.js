import Vue from 'vue';
import { GlBreakpointInstance as breakpointInstance } from '@gitlab/ui/dist/utils';
import WelcomePage from './components/welcome_page.vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import { redirectTo } from '~/lib/utils/url_utility';
import onboardingUtils from './../utils';

export default function() {
  const el = document.getElementById('js-onboarding-welcome');

  if (!el) {
    return false;
  }

  const { userAvatarUrl, projectFullPath, skipUrl, fromHelpMenu } = el.dataset;

  if (!breakpointInstance.isDesktop()) {
    onboardingUtils.updateOnboardingDismissed(true);
    return redirectTo(skipUrl);
  }

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
