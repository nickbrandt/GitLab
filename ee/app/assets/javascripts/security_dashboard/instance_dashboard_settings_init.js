import Vue from 'vue';
import InstanceReportSettings from './components/instance/instance_settings.vue';
import apolloProvider from './graphql/provider';

export default (el) => {
  if (!el) {
    return null;
  }

  return new Vue({
    el,
    apolloProvider,
    render(createElement) {
      return createElement(InstanceReportSettings);
    },
  });
};
