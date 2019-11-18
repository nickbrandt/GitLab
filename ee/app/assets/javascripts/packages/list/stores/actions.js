import Api from 'ee/api';
import createFlash from '~/flash';
import * as types from './mutation_types';
import {
  FETCH_PACKAGES_LIST_ERROR_MESSAGE,
  DELETE_PACKAGE_ERROR_MESSAGE,
  DELETE_PACKAGE_SUCCESS_MESSAGE,
  DEFAULT_PAGE,
  DEFAULT_PAGE_SIZE,
} from '../constants';

export const setInitialState = ({ commit }, data) => commit(types.SET_INITIAL_STATE, data);
export const setLoading = ({ commit }, data) => commit(types.SET_MAIN_LOADING, data);

export const receivePackagesListSuccess = ({ commit }, { data, headers }) => {
  commit(types.SET_PACKAGE_LIST_SUCCESS, data);
  commit(types.SET_PAGINATION, headers);
};

export const requestPackagesList = ({ dispatch, state }, pagination = {}) => {
  dispatch('setLoading', true);

  const { page = DEFAULT_PAGE, perPage = DEFAULT_PAGE_SIZE } = pagination;
  const apiMethod = state.config.isGroupPage ? 'groupPackages' : 'projectPackages';
  return Api[apiMethod](state.config.resourceId, { params: { page, per_page: perPage } })
    .then(({ data, headers }) => {
      dispatch('receivePackagesListSuccess', { data, headers });
    })
    .catch(() => {
      createFlash(FETCH_PACKAGES_LIST_ERROR_MESSAGE);
    })
    .finally(() => {
      dispatch('setLoading', false);
    });
};

export const requestDeletePackage = ({ dispatch }, { projectId, packageId }) => {
  dispatch('setLoading', true);
  return Api.deleteProjectPackage(projectId, packageId)
    .then(() => {
      dispatch('requestPackagesList');
      createFlash(DELETE_PACKAGE_SUCCESS_MESSAGE, 'success');
    })
    .catch(() => {
      createFlash(DELETE_PACKAGE_ERROR_MESSAGE);
    })
    .finally(() => {
      dispatch('setLoading', false);
    });
};

export default () => {};
