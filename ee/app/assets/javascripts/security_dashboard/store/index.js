import Vue from 'vue';
import Vuex from 'vuex';
import configureModerator from './moderator';
import filters from './modules/filters/index';
import projects from './modules/projects/index';
import vulnerabilities from './modules/vulnerabilities/index';

Vue.use(Vuex);

const store = new Vuex.Store({
  modules: {
    filters,
    projects,
    vulnerabilities,
  },
});

configureModerator(store);

export default () => store;
