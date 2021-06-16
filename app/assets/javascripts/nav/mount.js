import Vue from 'vue';
import VueApollo from 'vue-apollo';
import Vuex from 'vuex';
import createDefaultClient from '~/lib/graphql';
import ResponsiveApp from './components/responsive_app.vue';
import App from './components/top_nav_app.vue';
import AppWithCallout from './components/top_nav_app_with_callout.vue';
import { createStore } from './stores';
import { hasSeenTopNav } from './utils/has_seen_top_nav';

Vue.use(Vuex);
Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(),
});

const mount = (el, Component) => {
  const viewModel = JSON.parse(el.dataset.viewModel);
  const store = createStore();

  return new Vue({
    el,
    store,
    apolloProvider,
    render(h) {
      return h(Component, {
        props: {
          navData: viewModel,
        },
      });
    },
  });
};

export const mountTopNav = (el) => {
  // Showing the announcement callout has some costs to it.
  //
  // We allow for a localStorage flag to short circuit the
  // callout check. This helps us optimize for the most common
  // use case where the user has already seen the top nav menu
  // and doesn't want to incur the extra db or graphql cost.
  const component = hasSeenTopNav() ? App : AppWithCallout;

  return mount(el, component);
};

export const mountTopNavResponsive = (el) => mount(el, ResponsiveApp);
