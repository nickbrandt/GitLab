import Api from '~/api';
import httpStatus from '~/lib/utils/http_status';
import * as types from '../mutation_types';
import * as messages from '../messages';
import { CHECK_CONFIG, CHECK_RUNNERS, RETRY_RUNNERS_INTERVAL } from '../../../../constants';

export const requestConfigCheck = ({ commit }) => {
  commit(types.REQUEST_CHECK, CHECK_CONFIG);
};

export const receiveConfigCheckSuccess = ({ commit }) => {
  commit(types.SET_VISIBLE, true);
  commit(types.RECEIVE_CHECK_SUCCESS, CHECK_CONFIG);
};

export const receiveConfigCheckError = ({ commit, state }, e) => {
  const { status } = e.response;
  const { paths } = state;

  const isVisible = status !== httpStatus.FORBIDDEN && status !== httpStatus.NOT_FOUND;
  commit(types.SET_VISIBLE, isVisible);

  const message = messages.configCheckError(status, paths.ciYamlHelpPath);
  commit(types.RECEIVE_CHECK_ERROR, { type: CHECK_CONFIG, message });
};

export const fetchConfigCheck = ({ dispatch }) => {
  dispatch('requestConfigCheck');

  // This will use a real endpoint in https://gitlab.com/gitlab-org/gitlab-ee/issues/5426
  Promise.resolve({})
    .then(() => {
      dispatch('receiveConfigCheckSuccess');
    })
    .catch(e => {
      dispatch('receiveConfigCheckError', e);
    });
};

export const requestRunnersCheck = ({ commit }) => {
  commit(types.REQUEST_CHECK, CHECK_RUNNERS);
};

export const receiveRunnersCheckSuccess = ({ commit, dispatch, state }, data) => {
  if (data.length) {
    commit(types.RECEIVE_CHECK_SUCCESS, CHECK_RUNNERS);
  } else {
    const { paths } = state;

    commit(types.RECEIVE_CHECK_ERROR, {
      type: CHECK_RUNNERS,
      message: messages.runnersCheckEmpty(paths.ciRunnersHelpPath),
    });

    dispatch('retryRunnersCheck');
  }
};

export const receiveRunnersCheckError = ({ commit }) => {
  commit(types.RECEIVE_CHECK_ERROR, {
    type: CHECK_RUNNERS,
    message: messages.UNEXPECTED_ERROR_RUNNERS,
  });
};

export const retryRunnersCheck = ({ dispatch, state }) => {
  // if the overall check has failed, don't worry about retrying
  const check = state.checks[CHECK_CONFIG];
  if (!check.isLoading && !check.isValid) {
    return;
  }

  setTimeout(() => {
    dispatch('fetchRunnersCheck', { background: true });
  }, RETRY_RUNNERS_INTERVAL);
};

export const fetchRunnersCheck = ({ dispatch, rootGetters }, options = {}) => {
  const { background = false } = options;

  if (!background) {
    dispatch('requestRunnersCheck');
  }

  const { currentProject } = rootGetters;

  Api.projectRunners(currentProject.id, { params: { scope: 'active' } })
    .then(({ data }) => {
      dispatch('receiveRunnersCheckSuccess', data);
    })
    .catch(e => {
      dispatch('receiveRunnersCheckError', e);
    });
};
