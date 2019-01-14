import Vue from 'vue';
import Vuex from 'vuex';
import createStore from './stores';
import AppSettings from './components/app_settings.vue';

Vue.use(Vuex);

export default function mountApprovalSettings(el) {
  if (!el) {
    return null;
  }

  const store = createStore({
    ...el.dataset,
  });

  return new Vue({
    el,
    store,
    render(h) {
      return h(AppSettings);
    },
  });
}
