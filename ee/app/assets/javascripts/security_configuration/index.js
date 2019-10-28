import Vue from 'vue';
import SecurityConfigurationApp from './components/app.vue';

export default function init() {
  const el = document.getElementById('js-security-configuration');
  const { helpPagePath, features } = el.dataset;

  return new Vue({
    el,
    components: {
      SecurityConfigurationApp,
    },
    render(createElement) {
      return createElement(SecurityConfigurationApp, {
        props: {
          helpPagePath,
          features: JSON.parse(features),
        },
      });
    },
  });
}
