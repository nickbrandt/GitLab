import * as types from './mutation_types';
import { DEFAULT_TIMEOUT, DEFAULT_ALLOWED_IP } from '../constants';

export default {
  [types.REQUEST_GEO_SETTINGS](state) {
    state.isLoading = true;
  },
  [types.RECEIVE_GEO_SETTINGS_SUCCESS](state, { timeout, allowedIp }) {
    state.isLoading = false;
    state.timeout = timeout;
    state.allowedIp = allowedIp;
  },
  [types.RECEIVE_GEO_SETTINGS_ERROR](state) {
    state.isLoading = false;
    state.timeout = DEFAULT_TIMEOUT;
    state.allowedIp = DEFAULT_ALLOWED_IP;
  },
};
