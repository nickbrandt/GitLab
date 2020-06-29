import Api from 'ee/api';
import createFlash from '~/flash';
import { __ } from '~/locale';
import * as types from './mutation_types';

// eslint-disable-next-line import/prefer-default-export
export const fetchGeoSettings = ({ commit }) => {
  commit(types.REQUEST_GEO_SETTINGS);
  Api.getApplicationSettings()
    .then(({ data }) => {
      commit(types.RECEIVE_GEO_SETTINGS_SUCCESS, {
        timeout: data.geo_status_timeout,
        allowedIp: data.geo_node_allowed_ips,
      });
    })
    .catch(() => {
      createFlash(__('There was an error fetching the Geo Settings'));
      commit(types.RECEIVE_GEO_SETTINGS_ERROR);
    });
};
