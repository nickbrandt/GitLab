import Vue from 'vue';
import Vuex from 'vuex';
import createStore from './stores';
import Settings from './components/settings.vue';

Vue.use(Vuex);

export default function mountApprovalSettings(el) {
  if (!el) {
    return null;
  }

  const store = createStore();
  store.dispatch('setSettings', el.dataset);

  return new Vue({
    el,
    store,
    render(h) {
      return h(Settings);
    },
  });
}
