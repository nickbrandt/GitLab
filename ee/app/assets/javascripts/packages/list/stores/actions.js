import Api from 'ee/api';
import axios from '~/lib/utils/axios_utils';
import createFlash from '~/flash';
import * as types from './mutation_types';
import {
  FETCH_PACKAGES_LIST_ERROR_MESSAGE,
  DELETE_PACKAGE_ERROR_MESSAGE,
  DELETE_PACKAGE_SUCCESS_MESSAGE,
  DEFAULT_PAGE,
  DEFAULT_PAGE_SIZE,
  MISSING_DELETE_PATH_ERROR,
} from '../constants';

export const setInitialState = ({ commit }, data) => commit(types.SET_INITIAL_STATE, data);
export const setLoading = ({ commit }, data) => commit(types.SET_MAIN_LOADING, data);
export const setSorting = ({ commit }, data) => commit(types.SET_SORTING, data);

export const receivePackagesListSuccess = ({ commit }, { data, headers }) => {
  commit(types.SET_PACKAGE_LIST_SUCCESS, data);
  commit(types.SET_PAGINATION, headers);
};

export const requestPackagesList = ({ dispatch, state }, pagination = {}) => {
  dispatch('setLoading', true);

  const { page = DEFAULT_PAGE, per_page = DEFAULT_PAGE_SIZE } = pagination;
  const { sort, orderBy } = state.sorting;
  const apiMethod = state.config.isGroupPage ? 'groupPackages' : 'projectPackages';
  return Api[apiMethod](state.config.resourceId, {
    params: { page, per_page, sort, order_by: orderBy },
  })
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

export const requestDeletePackage = ({ dispatch }, { _links }) => {
  if (!_links || !_links.delete_api_path) {
    createFlash(DELETE_PACKAGE_ERROR_MESSAGE);
    const error = new Error(MISSING_DELETE_PATH_ERROR);
    return Promise.reject(error);
  }

  dispatch('setLoading', true);
  return axios
    .delete(_links.delete_api_path)
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
