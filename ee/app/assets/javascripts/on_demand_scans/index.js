import Vue from 'vue';
import apolloProvider from './graphql/provider';
import OnDemandScansApp from './components/on_demand_scans_app.vue';

export default () => {
  const el = document.querySelector('#js-on-demand-scans-app');
  if (!el) {
    return;
  }

  const { helpPagePath, emptyStateSvgPath, projectPath, defaultBranch } = el.dataset;

  // eslint-disable-next-line no-new
  new Vue({
    el,
    apolloProvider,
    render(h) {
      return h(OnDemandScansApp, {
        props: {
          helpPagePath,
          emptyStateSvgPath,
          projectPath,
          defaultBranch,
        },
      });
    },
  });
};
