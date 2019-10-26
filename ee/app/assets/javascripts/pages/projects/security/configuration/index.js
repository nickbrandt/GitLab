import Vue from 'vue';
// @TODO - set up store
// import createStore from 'ee/security_dashboard/store';
import SecurityConfigurationApp from 'ee/security_configuration/components/app.vue';

// @TODO - feature flags, check how they are set up and enabled locally
// if (gon.features && gon.features.securityDashboard) {
document.addEventListener(
  'DOMContentLoaded',
  () =>
    new Vue({
      el: '#js-security-configuration',
      // store: createStore(),
      components: {
        SecurityConfigurationApp,
      },
      render(createElement) {
        return createElement(SecurityConfigurationApp, {
          props: {
            helpPagePath: 'http://google.com',
          },
        });
      },
    }),
);
// }
