import Vue from 'vue';
import Vuex from 'vuex';
import createStore from './stores';
import AppInput from './components/app_input.vue';

Vue.use(Vuex);

export default function mountApprovalInput(el) {
  if (!el) {
    return null;
  }

  const store = createStore();
  store.dispatch('setSettings', el.dataset);

  return new Vue({
    el,
    store,
    render(h) {
      return h(AppInput);
    },
  });
}
