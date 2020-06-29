import testAction from 'helpers/vuex_action_helper';
import flash from '~/flash';
import Api from 'ee/api';
import * as actions from 'ee/geo_settings/store/actions';
import * as types from 'ee/geo_settings/store/mutation_types';
import state from 'ee/geo_settings/store/state';
import { MOCK_BASIC_SETTINGS_DATA, MOCK_APPLICATION_SETTINGS_FETCH_RESPONSE } from '../mock_data';

jest.mock('~/flash');

describe('GeoSettings Store Actions', () => {
  describe('fetchGeoSettings', () => {
    describe('on success', () => {
      beforeEach(() => {
        jest
          .spyOn(Api, 'getApplicationSettings')
          .mockResolvedValue({ data: MOCK_APPLICATION_SETTINGS_FETCH_RESPONSE });
      });

      it('should commit the request and success actions', done => {
        testAction(
          actions.fetchGeoSettings,
          {},
          state,
          [
            { type: types.REQUEST_GEO_SETTINGS },
            { type: types.RECEIVE_GEO_SETTINGS_SUCCESS, payload: MOCK_BASIC_SETTINGS_DATA },
          ],
          [],
          done,
        );
      });
    });

    describe('on error', () => {
      beforeEach(() => {
        jest.spyOn(Api, 'getApplicationSettings').mockRejectedValue(new Error(500));
      });

      it('should commit the request and error actions', () => {
        testAction(
          actions.fetchGeoSettings,
          {},
          state,
          [{ type: types.REQUEST_GEO_SETTINGS }, { type: types.RECEIVE_GEO_SETTINGS_ERROR }],
          [],
          () => {
            expect(flash).toHaveBeenCalledTimes(1);
          },
        );
      });
    });
  });
});
