import * as types from './mutation_types';

export default {
  [types.TOGGLE_LOADING](state) {
    Object.assign(state, { isLoading: !state.isLoading });
  },

  [types.SET_PIPELINE_ERROR](state, pipelineError) {
    Object.assign(state, { pipelineError });
  },

  [types.SET_PIPELINE_INFO](state, pipelineInfo) {
    Object.assign(state, { pipelineInfo });
  },
};
