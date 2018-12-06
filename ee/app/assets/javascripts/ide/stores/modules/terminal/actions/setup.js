import * as types from '../mutation_types';

// This will be used in https://gitlab.com/gitlab-org/gitlab-ee/issues/5426
// export const init = ({ dispatch }) => {
//   dispatch('fetchConfigCheck');
//   dispatch('fetchRunnersCheck');
// };
export const init = () => {};

export const hideSplash = ({ commit }) => {
  commit(types.HIDE_SPLASH);
};

export const setPaths = ({ commit }, paths) => {
  commit(types.SET_PATHS, paths);
};
