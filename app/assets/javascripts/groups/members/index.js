import Vue from 'vue';
import Vuex from 'vuex';
import App from './components/app.vue';
import { createStore } from '~/vuex_shared/modules/members';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';

export default el => {
  if (!el) {
    return () => {};
  }

  Vue.use(Vuex);

  const { members, groupId, currentUserId } = el.dataset;

  const store = createStore({
    members: convertObjectPropsToCamelCase(JSON.parse(members), { deep: true }),
    sourceId: parseInt(groupId, 10),
    currentUserId: currentUserId ? parseInt(currentUserId, 10) : null,
  });

  return new Vue({
    el,
    components: { App },
    store,
    render: createElement => createElement('app'),
  });
};
