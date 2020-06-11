import { escape } from 'lodash';
import flash from '~/flash';
import { __, sprintf } from '~/locale';
import service from '../../services';
import api from '../../../api';
import * as types from '../mutation_types';

export const getProjectData = ({ commit, state }, { namespace, projectId } = {}) => {
  if (state.project && state.currentProjectId === `${namespace}/${projectId}`) {
    return Promise.resolve();
  }

  commit(types.TOGGLE_LOADING, { entry: state });

  return service
    .getProjectData(namespace, projectId)
    .then(res => res.data)
    .then(data => {
      commit(types.TOGGLE_LOADING, { entry: state });
      commit(types.SET_PROJECT, data);
      commit(types.SET_CURRENT_PROJECT, `${namespace}/${projectId}`);
    })
    .catch(() => {
      flash(
        __('Error loading project data. Please try again.'),
        'alert',
        document,
        null,
        false,
        true,
      );
      throw new Error(`Project not loaded ${namespace}/${projectId}`);
    });
};

export const refreshLastCommitData = ({ state, commit }) => {
  const projectId = state.currentProjectId;
  const branchId = state.currentBranchId;

  service
    .getBranchData(projectId, branchId)
    .then(({ data }) => {
      commit(types.SET_BRANCH_COMMIT, {
        branchId,
        commit: data.commit,
      });
    })
    .catch(() => {
      flash(__('Error loading last commit.'), 'alert', document, null, false, true);
    });
};

export const createNewBranchFromDefault = ({ state, dispatch, getters }, branch) =>
  api
    .createBranch(state.currentProjectId, {
      ref: getters.currentProject.default_branch,
      branch,
    })
    .then(() => {
      dispatch('setErrorMessage', null);
      window.location.reload();
    })
    .catch(() => {
      dispatch('setErrorMessage', {
        text: __('An error occurred creating the new branch.'),
        action: payload => dispatch('createNewBranchFromDefault', payload),
        actionText: __('Please try again'),
        actionPayload: branch,
      });
    });

export const showBranchNotFoundError = ({ dispatch }, branchId) => {
  dispatch('setErrorMessage', {
    text: sprintf(
      __("Branch %{branchName} was not found in this project's repository."),
      {
        branchName: `<strong>${escape(branchId)}</strong>`,
      },
      false,
    ),
    action: payload => dispatch('createNewBranchFromDefault', payload),
    actionText: __('Create branch'),
    actionPayload: branchId,
  });
};

export const loadEmptyBranch = ({ commit, state, getters }, { branchId }) => {
  const projectId = state.currentProjectId;
  const treePath = `${projectId}/${branchId}`;

  // If we already have a tree, let's not recreate an empty one
  if (getters.currentTree) {
    return;
  }

  commit(types.TOGGLE_LOADING, {
    entry: state.trees[treePath],
    forceValue: false,
  });
};

export const loadFile = ({ dispatch }, { basePath }) => {
  if (basePath) {
    const path = basePath.slice(-1) === '/' ? basePath.slice(0, -1) : basePath;

    dispatch('handleTreeEntryAction', path);
  }
};

export const loadBranch = ({ dispatch, getters, state }, { branchId }) => {
  const currentProject = state.project;

  if (currentProject?.branches?.[branchId]) {
    return Promise.resolve();
  } else if (getters.emptyRepo) {
    return dispatch('loadEmptyBranch', { branchId });
  }

  return dispatch('getBranchData', {
    branchId,
  })
    .then(() => {
      dispatch('getMergeRequestsForBranch', {
        branchId,
      });

      const branch = getters.findBranch(branchId);

      return dispatch('getFiles', {
        branchId,
        ref: branch.commit.id,
      });
    })
    .catch(err => {
      dispatch('showBranchNotFoundError', branchId);
      throw err;
    });
};

export const openBranch = ({ state, dispatch }, { branchId, basePath }) => {
  dispatch('setCurrentBranchId', branchId);

  return dispatch('loadBranch', { branchId })
    .then(() => dispatch('loadFile', { basePath }))
    .catch(
      () =>
        new Error(
          sprintf(
            __('An error occurred while getting files for - %{branchId}'),
            {
              branchId: `<strong>${escape(state.currentProjectId)}/${escape(branchId)}</strong>`,
            },
            false,
          ),
        ),
    );
};
