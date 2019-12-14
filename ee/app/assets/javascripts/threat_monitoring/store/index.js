import Vue from 'vue';
import Vuex from 'vuex';
import threatMonitoring from './modules/threat_monitoring';

Vue.use(Vuex);

export default () =>
  new Vuex.Store({
    modules: {
      threatMonitoring: threatMonitoring(),
    },
  });
