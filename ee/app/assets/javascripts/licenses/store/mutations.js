import * as types from './mutation_types';

export default {
  [types.SET_INITIAL_DATA](state, data) {
    Object.assign(state, data);
  },

  [types.REQUEST_LICENSES](state) {
    state.isLoadingLicenses = true;
  },

  [types.RECEIVE_LICENSES_SUCCESS](state, licenses = []) {
    state.isLoadingLicenses = false;

    state.licenses = licenses;
  },

  [types.RECEIVE_LICENSES_ERROR](state) {
    state.isLoadingLicenses = false;
  },

  [types.REQUEST_DELETE_LICENSE](state, { id }) {
    if (state.deleteQueue.includes(id)) return;

    state.deleteQueue.push(id);
  },

  [types.RECEIVE_DELETE_LICENSE_SUCCESS](state, { id }) {
    const queueIndex = state.deleteQueue.indexOf(id);
    const licenseIndex = state.licenses.findIndex(license => id === license.id);

    if (queueIndex !== -1) state.deleteQueue.splice(queueIndex, 1);
    if (licenseIndex !== -1) state.licenses.splice(licenseIndex, 1);
  },

  [types.RECEIVE_DELETE_LICENSE_ERROR](state, { id }) {
    const queueIndex = state.deleteQueue.indexOf(id);

    if (queueIndex !== -1) state.deleteQueue.splice(queueIndex, 1);
  },
};
