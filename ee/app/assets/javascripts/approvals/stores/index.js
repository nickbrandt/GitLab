import Vuex from 'vuex';
import modalModule from '~/vuex_shared/modules/modal';
import state from './state';

export const createStoreOptions = (rulesModule, settings) => ({
  state: state(settings),
  modules: {
    rules: rulesModule,
    createModal: modalModule(),
    deleteModal: modalModule(),
  },
});

export default (rulesModule, settings = {}) =>
  new Vuex.Store(createStoreOptions(rulesModule, settings));
