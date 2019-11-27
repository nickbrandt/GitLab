import MockAdapter from 'axios-mock-adapter';
import testAction from 'helpers/vuex_action_helper';
import axios from '~/lib/utils/axios_utils';
import flash from '~/flash';
import * as actions from 'ee/geo_designs/store/actions';
import * as types from 'ee/geo_designs/store/mutation_types';
import createState from 'ee/geo_designs/store/state';
import { MOCK_BASIC_FETCH_DATA_MAP, MOCK_BASIC_FETCH_RESPONSE } from '../mock_data';

jest.mock('~/flash');

describe('GeoDesigns Store Actions', () => {
  let state;
  beforeEach(() => {
    state = createState();
  });

  describe('requestDesigns', () => {
    it('should commit mutation REQUEST_DESIGNS', done => {
      testAction(actions.requestDesigns, null, state, [{ type: types.REQUEST_DESIGNS }], [], done);
    });
  });

  describe('receiveDesignsSuccess', () => {
    it('should commit mutation RECEIVE_DESIGNS_SUCCESS', done => {
      testAction(
        actions.receiveDesignsSuccess,
        MOCK_BASIC_FETCH_DATA_MAP,
        state,
        [{ type: types.RECEIVE_DESIGNS_SUCCESS, payload: MOCK_BASIC_FETCH_DATA_MAP }],
        [],
        done,
      );
    });
  });

  describe('receiveDesignsError', () => {
    it('should commit mutation RECEIVE_DESIGNS_ERROR and call flash', done => {
      testAction(
        actions.receiveDesignsError,
        null,
        state,
        [{ type: types.RECEIVE_DESIGNS_ERROR }],
        [],
        done,
      );
      expect(flash).toHaveBeenCalledTimes(1);
    });
  });

  describe('fetchDesigns', () => {
    let mock;
    beforeEach(() => {
      mock = new MockAdapter(axios);
    });

    afterEach(() => {
      mock.restore();
    });

    describe('on success', () => {
      beforeEach(() => {
        mock
          .onGet()
          .replyOnce(200, MOCK_BASIC_FETCH_RESPONSE.data, MOCK_BASIC_FETCH_RESPONSE.headers);
      });

      it('should dispatch the request and success actions', done => {
        testAction(
          actions.fetchDesigns,
          {},
          state,
          [],
          [
            { type: 'requestDesigns' },
            { type: 'receiveDesignsSuccess', payload: MOCK_BASIC_FETCH_DATA_MAP },
          ],
          done,
        );
      });
    });

    describe('on error', () => {
      beforeEach(() => {
        mock.onGet().replyOnce(500, {});
      });

      it('should dispatch the request and error actions', done => {
        testAction(
          actions.fetchDesigns,
          {},
          state,
          [],
          [{ type: 'requestDesigns' }, { type: 'receiveDesignsError' }],
          done,
        );
      });
    });
  });

  describe('setPage', () => {
    it('should commit mutation SET_PAGE', done => {
      testAction(actions.setPage, 2, state, [{ type: types.SET_PAGE, payload: 2 }], [], done);
    });
  });
});
