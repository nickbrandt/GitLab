import Vue from 'vue';
import Vuex from 'vuex';
import { queryToObject } from '~/lib/utils/url_utility';
import ReportsApp from './components/app.vue';
import createsStore from './store';

Vue.use(Vuex);

export default () => {
  const el = document.querySelector('#js-reports-app');

  if (!el) return false;

  const store = createsStore();

  const { configEndpoint } = el.dataset;
  const { groupName = null, groupPath = null, reportId = null } = queryToObject(
    document.location.search,
  );

  store.dispatch('page/setInitialPageData', { configEndpoint, groupName, groupPath, reportId });

  return new Vue({
    el,
    name: 'ReportsApp',
    store,
    render: createElement => createElement(ReportsApp),
  });
};
