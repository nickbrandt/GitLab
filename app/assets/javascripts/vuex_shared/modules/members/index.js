import Vuex from 'vuex';
import createState from './state';

export const createStore = initialState =>
  new Vuex.Store({
    state: createState(initialState),
  });
