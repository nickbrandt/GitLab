import mutations from 'ee/geo_settings/store/mutations';
import createState from 'ee/geo_settings/store/state';
import * as types from 'ee/geo_settings/store/mutation_types';
import { DEFAULT_TIMEOUT, DEFAULT_ALLOWED_IP } from 'ee/geo_settings/constants';
import { MOCK_BASIC_SETTINGS_DATA } from '../mock_data';

describe('GeoSettings Store Mutations', () => {
  let state;

  beforeEach(() => {
    state = createState();
  });

  describe('REQUEST_GEO_SETTINGS', () => {
    it('sets isLoading to true', () => {
      mutations[types.REQUEST_GEO_SETTINGS](state);

      expect(state.isLoading).toEqual(true);
    });
  });

  describe('RECEIVE_GEO_SETTINGS_SUCCESS', () => {
    const mockData = MOCK_BASIC_SETTINGS_DATA;

    beforeEach(() => {
      state.isLoading = true;
    });

    it('sets isLoading to false', () => {
      mutations[types.RECEIVE_GEO_SETTINGS_SUCCESS](state, mockData);

      expect(state.isLoading).toEqual(false);
    });

    it('sets timeout and allowedIp array with data', () => {
      mutations[types.RECEIVE_GEO_SETTINGS_SUCCESS](state, mockData);

      expect(state.timeout).toBe(mockData.timeout);
      expect(state.allowedIp).toBe(mockData.allowedIp);
    });
  });

  describe('RECEIVE_GEO_SETTINGS_ERROR', () => {
    const mockData = MOCK_BASIC_SETTINGS_DATA;

    beforeEach(() => {
      state.isLoading = true;
      state.timeout = mockData.timeout;
      state.allowedIp = mockData.allowedIp;
    });

    it('sets isLoading to false', () => {
      mutations[types.RECEIVE_GEO_SETTINGS_ERROR](state);

      expect(state.isLoading).toEqual(false);
    });

    it('resets timeout and allowedIp array', () => {
      mutations[types.RECEIVE_GEO_SETTINGS_ERROR](state);

      expect(state.timeout).toBe(DEFAULT_TIMEOUT);
      expect(state.allowedIp).toBe(DEFAULT_ALLOWED_IP);
    });
  });
});
