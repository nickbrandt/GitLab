import Vue from 'vue';
import Vuex from 'vuex';
import * as actions from './actions';
import * as getters from './getters';
import mutations from './mutations';
import createState from './state';
import createClusterDropdownStore from '~/create_cluster/store/cluster_dropdown';

import { fetchNetworks, fetchSubnetworks } from '../services/google_api_facade';

Vue.use(Vuex);

export const createStore = () =>
  new Vuex.Store({
    actions,
    getters,
    mutations,
    state: createState(),
    modules: {
      networks: {
        namespaced: true,
        ...createClusterDropdownStore({ fetchFn: fetchNetworks }),
      },
      subnetworks: {
        namespaced: true,
        ...createClusterDropdownStore({ fetchFn: fetchSubnetworks }),
      },
    },
  });

export default createStore();
