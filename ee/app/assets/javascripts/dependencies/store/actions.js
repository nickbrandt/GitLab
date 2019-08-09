import * as types from './mutation_types';

export const addListType = ({ commit }, payload) => commit(types.ADD_LIST_TYPE, payload);

export const setDependenciesEndpoint = ({ state, dispatch }, endpoint) =>
  Promise.all(
    state.listTypes.map(({ namespace }) =>
      dispatch(`${namespace}/setDependenciesEndpoint`, endpoint),
    ),
  );

export const fetchDependencies = ({ state, dispatch }, payload) =>
  Promise.all(
    state.listTypes.map(({ namespace }) => dispatch(`${namespace}/fetchDependencies`, payload)),
  );

export const setCurrentList = ({ state, commit }, payload) => {
  if (state.listTypes.map(({ namespace }) => namespace).includes(payload)) {
    commit(types.SET_CURRENT_LIST, payload);
  }
};
