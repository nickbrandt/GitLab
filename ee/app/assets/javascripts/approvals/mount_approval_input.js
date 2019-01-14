import Vue from 'vue';
import Vuex from 'vuex';
import { parseBoolean } from '~/lib/utils/common_utils';
import createStore from './stores';
import AppInput from './components/app_input.vue';

Vue.use(Vuex);

export default function mountApprovalInput(el) {
  if (!el) {
    return null;
  }

  const store = createStore({
    ...el.dataset,
    canEdit: parseBoolean(el.dataset.canEdit),
  });

  return new Vue({
    el,
    store,
    render(h) {
      return h(AppInput);
    },
  });
}
