import Vue from 'vue';
import Vuex from 'vuex';
import state from './state';
import * as actions from './actions';
import * as getters from './getters';
import mutations from './mutations';
import commitModule from './modules/commit';
import pipelines from './modules/pipelines';
import mergeRequests from './modules/merge_requests';
import branches from './modules/branches';
import fileTemplates from './modules/file_templates';
import fileSystem from './modules/file_system';
import paneModule from './modules/pane';
import clientsideModule from './modules/clientside';
import routerModule from './modules/router';
import editorModule from './modules/editor';

Vue.use(Vuex);

export const createStoreOptions = () => ({
  state: state(),
  actions,
  mutations,
  getters,
  modules: {
    commit: commitModule,
    pipelines,
    mergeRequests,
    branches,
    fileSystem,
    fileTemplates: fileTemplates(),
    rightPane: paneModule(),
    clientside: clientsideModule(),
    router: routerModule,
    editor: editorModule,
  },
});

export const createStore = () => new Vuex.Store(createStoreOptions());

export default createStore();
