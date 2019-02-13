import Vue from 'vue';
import Vuex from 'vuex';
import router from './router';
import configureModerator from './moderator';
import filters from './modules/filters/index';
import projects from './modules/projects/index';
import vulnerabilities from './modules/vulnerabilities/index';

Vue.use(Vuex);

export default () => {
  const store = new Vuex.Store({
    modules: {
      filters,
      projects,
      vulnerabilities,
    },
  });

  store.$router = router;

  configureModerator(store);

  return store;
};
