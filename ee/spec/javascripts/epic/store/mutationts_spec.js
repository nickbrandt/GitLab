import mutations from 'ee/epic/store/mutations';
import * as types from 'ee/epic/store/mutation_types';

import { mockEpicMeta, mockEpicData } from '../mock_data';

describe('Epic Store Mutations', () => {
  describe('SET_EPIC_META', () => {
    it('Should add Epic meta to state', () => {
      const state = {};
      mutations[types.SET_EPIC_META](state, mockEpicMeta);

      expect(state).toEqual(mockEpicMeta);
    });
  });

  describe('SET_EPIC_DATA', () => {
    it('Should add Epic data to state', () => {
      const state = {};
      mutations[types.SET_EPIC_DATA](state, mockEpicData);

      expect(state).toEqual(mockEpicData);
    });
  });

  describe('REQUEST_EPIC_STATUS_CHANGE', () => {
    it('Should set `epicStatusChangeInProgress` flag on state as `true`', () => {
      const state = {};
      mutations[types.REQUEST_EPIC_STATUS_CHANGE](state);

      expect(state.epicStatusChangeInProgress).toBe(true);
    });
  });

  describe('REQUEST_EPIC_STATUS_CHANGE_SUCCESS', () => {
    it('Should set `epicStatusChangeInProgress` flag on state as `false` and update Epic `state`', () => {
      const state = {
        state: 'opened',
      };
      mutations[types.REQUEST_EPIC_STATUS_CHANGE_SUCCESS](state, { state: 'closed' });

      expect(state.epicStatusChangeInProgress).toBe(false);
      expect(state.state).toBe('closed');
    });
  });

  describe('REQUEST_EPIC_STATUS_CHANGE_FAILURE', () => {
    it('Should set `epicStatusChangeInProgress` flag on state as `false`', () => {
      const state = {};
      mutations[types.REQUEST_EPIC_STATUS_CHANGE_FAILURE](state);

      expect(state.epicStatusChangeInProgress).toBe(false);
    });
  });

  describe('TOGGLE_SIDEBAR', () => {
    it('Should set `sidebarCollapsed` flag on state with value of provided `sidebarCollapsed` param', () => {
      const state = {};
      const sidebarCollapsed = true;

      mutations[types.TOGGLE_SIDEBAR](state, sidebarCollapsed);

      expect(state.sidebarCollapsed).toBe(sidebarCollapsed);
    });
  });
});
