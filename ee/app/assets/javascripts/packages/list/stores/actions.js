import Api from '~/api';
import createFlash from '~/flash';
import * as types from './mutation_types';
import { FETCH_PACKAGES_LIST_ERROR_MESSAGE, DELETE_PACKAGE_ERROR_MESSAGE } from '../constants';

export const setProjectId = ({ commit }, data) => commit(types.SET_PROJECT_ID, data);
export const setUserCanDelete = ({ commit }, data) => commit(types.SET_USER_CAN_DELETE, data);
export const setLoading = ({ commit }, data) => commit(types.SET_MAIN_LOADING, data);

export const receivePackagesListSuccess = ({ commit }, data) =>
  commit(types.SET_PACKAGE_LIST_SUCCESS, data);

export const requestPackagesList = ({ dispatch, state }) => {
  dispatch('setLoading', true);

  const { page, perPage } = state.pagination;

  return Api.projectPackages(state.projectId, { params: { page, perPage } })
    .then(({ data }) => {
      dispatch('receivePackagesListSuccess', data);
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
    .then(() => dispatch('fetchPackages'))
    .catch(() => {
      createFlash(DELETE_PACKAGE_ERROR_MESSAGE);
    })
    .finally(() => {
      dispatch('setLoading', false);
    });
};

export default () => {};
