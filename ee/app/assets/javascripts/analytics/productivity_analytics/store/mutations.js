import SET_ENDPOINT from './mutation_types';

export default {
  [SET_ENDPOINT](state, endpoint) {
    state.endpoint = endpoint;
  },
};
