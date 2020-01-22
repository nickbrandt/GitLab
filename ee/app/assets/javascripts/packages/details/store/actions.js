import Api from '~/api';
import * as types from './mutation_types';
import createFlash from '~/flash';
import { s__ } from '~/locale';

export const toggleLoading = ({ commit }) => commit(types.TOGGLE_LOADING);

export const fetchPipelineInfo = ({ state, commit, dispatch }) => {
  const {
    project_id: projectId,
    build_info: { pipeline_id: pipelineId } = {},
  } = state.packageEntity;

  if (projectId && pipelineId) {
    dispatch('toggleLoading');

    Api.pipelineSingle(projectId, pipelineId)
      .then(response => {
        const { data } = response;
        commit(types.SET_PIPELINE_ERROR, null);
        commit(types.SET_PIPELINE_INFO, data);
      })
      .catch(() => {
        createFlash(s__('PackageRegistry|There was an error fetching the pipeline information.'));
        commit(
          types.SET_PIPELINE_ERROR,
          s__('PackageRegistry|Unable to fetch pipeline information'),
        );
      })
      .finally(() => {
        dispatch('toggleLoading');
      });
  }
};
